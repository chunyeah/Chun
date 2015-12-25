//
//  Chun.swift
//  ChunImage
//
//  Created by Chun Ye on 3/5/15.
//  Copyright (c) 2015 Chun Tips. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

// MARK: - CONSTANTS

let CHUN_BASE_DOMAIN = ".image.chun.tips"
let CHUN_ERROR_DOMAIN = "error" + CHUN_BASE_DOMAIN

// MARK: - UIImageView Improvement

private var key = 0

public extension UIImageView {
    
    /**
     Set the imageView image with image url.
     We will fetch and cache the image asynchronous.
     
     - parameter url: the local or remote url for the image
     */
    public func setImageWithURL(url: NSURL) {
        self.setImageWithURL(url, placeholderImage: nil)
    }
    
    /**
     Set the imageView image with the image url
     Before the url image load, will display placeholderImage
     
     - parameter url: the local or remote url for the image
     - parameter placeholderImage: the image to be set initially
     */
    public func setImageWithURL(url: NSURL, placeholderImage: UIImage?) {
        
        if let imageURLForChun = self.imageURLForChun {
            Chun.sharedInstance.cancelFetchWithURL(imageURLForChun)
        }
        
        self.imageURLForChun = url
        
        if let placeholderImage = placeholderImage {
            self.image = placeholderImage
        }
        
        Chun.sharedInstance.fetchImageWithURL(url, complete: { [weak self](result: Result) -> Void in
            
            switch result {
            case let .Error(error):
                print(error)
            case let .Success(image, fetchedImageURL):
                if let strongSelf = self {
                    if let imageURLForChun = strongSelf.imageURLForChun {
                        if imageURLForChun == fetchedImageURL {
                            dispatch_main_sync_safe() {
                                strongSelf.image = image
                                strongSelf.setNeedsLayout()
                            }
                        }
                    }
                }
            }
            
            })
    }
    
    private var imageURLForChun: NSURL? {
        get {
            return objc_getAssociatedObject(self, &key) as? NSURL
        }
        set (url) {
            objc_setAssociatedObject(self, &key, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Cache and Fetch Image manager

public enum Result {
    case Success(image: UIImage, fetchedImageURL: NSURL)
    case Error(error: NSError)
}

public class Chun {
    
    private static let sharedInstance = Chun()
    
    /// Shared instance to manage the web image fetch and cache
    public static var shared: Chun {
        return sharedInstance
    }
    
    private let cache = ImageCache()
    private lazy var fetchers = [String: ImageFetcher]()
    
    /**
     Cancel and remove all fetch
     */
    public func destroyAllFetch() {
        for fetcher in self.fetchers.values {
            fetcher.cancelFetch()
        }
        self.fetchers.removeAll(keepCapacity: false)
    }
    
    /**
     Fetch image with local or remote url
     
     - parameter url:      the image url
     - parameter complete: callback when the fetch comlete
     */
    public func fetchImageWithURL(url: NSURL, complete: (Result) -> Void) {
        let key = cacheKeyForRemoteURL(url)
        
        if let image = cache.imageForMemeoryCacheWithKey(key) {
            let result = Result.Success(image: image, fetchedImageURL: url)
            complete(result)
        } else {
            if fetchers[key] == nil {
                cache.diskImageExistsWithKey(key, completion: { [unowned self](exist: Bool, diskURL: NSURL?) -> Void in
                    var fetchURL = url
                    if exist {
                        fetchURL = diskURL!
                    }
                    let fetcher = ImageFetcher.fetchImage(fetchURL, completion: { (result: FetcherResult) -> Void in
                        switch result {
                        case let .Error(error):
                            let result = Result.Error(error: error)
                            complete(result)
                        case let .Success(image, imageData):
                            let result = Result.Success(image: image, fetchedImageURL: url)
                            complete(result)
                            self.cache.storeImage(image, imageData: imageData, key: key)
                        }
                        self.fetchers[key] = nil
                    })
                    self.fetchers[key] = fetcher
                    })
            }
        }
    }
    
    /**
     cancel fetch with image url
     
     - parameter url: the url witch waht to cancel
     */
    public func cancelFetchWithURL(url: NSURL) {
        
        let key = cacheKeyForRemoteURL(url)
        
        if let fetcher = self.fetchers[key] {
            fetcher.cancelFetch()
            self.fetchers[key] = nil
        }
    }
    
    /**
     Clear all cached image files in the disk
     */
    public func clearDisk() {
        self.cache.clearDisk(){}
    }
    
    /**
     Clear all cached images in the memory
     */
    public func clearMemory() {
        self.cache.clearMemory()
    }
}

// MARK: - Helps

func dispatch_main_sync_safe(closure: ()->Void) {
    if NSThread.isMainThread() {
        closure()
    } else {
        dispatch_sync(dispatch_get_main_queue()) {
            closure()
        }
    }
}

func dispatch_main_async_safe(closure: ()->Void) {
    if NSThread.isMainThread() {
        closure()
    } else {
        dispatch_async(dispatch_get_main_queue()) {
            closure()
        }
    }
}

func md5String(string: String) -> String {
    if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
        let md5Calculator = MD5(data)
        let md5Data = md5Calculator.calculate()
        let resultBytes = UnsafeMutablePointer<CUnsignedChar>(md5Data.bytes)
        let resultEnumerator = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: md5Data.length)
        let md5String = NSMutableString()
        for c in resultEnumerator {
            md5String.appendFormat("%02x", c)
        }
        return md5String as String
    } else {
        return string
    }
}

func cacheKeyForRemoteURL(url: NSURL) -> String {
    return url.absoluteString
}

func == (left: NSURL, right: NSURL) -> Bool {
    return left.absoluteString == right.absoluteString
}

// MARK: - ImageUtils

func scaledImage(image: UIImage) -> UIImage {
    if image.images != nil && image.images?.count > 0 {
        var scaledImages = [UIImage]()
        for tempImage in image.images! {
            scaledImages.append(scaledImage(tempImage))
        }
        if let image = UIImage.animatedImageWithImages(scaledImages, duration: image.duration){
            return image
        }
        else{
            return image
        }
    }
    else {
        return image
    }
}

func decodedImageWithImage(image: UIImage) -> UIImage {
    if image.images != nil {
        return image
    }
    let imageRef = image.CGImage
    let imageSize: CGSize = CGSizeMake(CGFloat(CGImageGetWidth(imageRef)), CGFloat(CGImageGetHeight(imageRef)))
    let imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let originalBitmapInfo = CGImageGetBitmapInfo(imageRef)
    let alphaInfo = CGImageGetAlphaInfo(imageRef)
    
    var bitmapInfo = originalBitmapInfo
    switch (alphaInfo) {
    case .None:
        bitmapInfo = [.ByteOrder32Little, CGBitmapInfo(rawValue: ~CGBitmapInfo.AlphaInfoMask.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)]
    case .PremultipliedFirst, .PremultipliedLast, .NoneSkipFirst, .NoneSkipLast:
        break
    case .Only, .Last, .First:
        return image
    }
    
    if let context = CGBitmapContextCreate(nil, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef), CGImageGetBitsPerComponent(imageRef), 0 , colorSpace, bitmapInfo.rawValue) {
        CGContextDrawImage(context, imageRect, imageRef)
        
        if let decompressedImageRef = CGBitmapContextCreateImage(context){
            return UIImage(CGImage: decompressedImageRef, scale: image.scale, orientation: image.imageOrientation)
        }
        else{
            return image
        }
    } else {
        return image
    }
}

func imageWithData(data: NSData) -> UIImage? {
    
    var image: UIImage?
    
    if let imageType = contentTypeForImageData(data) {
        if imageType == "image/gif" {
            return  animatedGIFWithData(data)
        }
        else {
            image = UIImage(data: data)
            let orientation = imageOrientationFromImageData(data)
            if orientation != UIImageOrientation.Up {
                if let tempImage = image, let tempCGImage = image?.CGImage{
                    image = UIImage(CGImage: tempCGImage, scale: tempImage.scale, orientation: orientation)
                    
                }
            }
        }
    }
    return image
}

func imageOrientationFromImageData(imageData: NSData) -> UIImageOrientation {
    var result = UIImageOrientation.Up
    if let imageSource = CGImageSourceCreateWithData(imageData, nil) {
        if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) {
            let prop = properties as NSDictionary
            var exifOrientation = 0
            if let value: AnyObject = prop[kCGImagePropertyOrientation as NSString] {
                CFNumberGetValue(value as! CFNumber, CFNumberType.IntType, &exifOrientation)
                result = exifOrientationToiOSOrientation(exifOrientation)
            }
        }
    }
    return result
}

func exifOrientationToiOSOrientation(exifOrientation: Int) -> UIImageOrientation {
    var orientation = UIImageOrientation.Up
    switch (exifOrientation) {
    case 1:
        orientation = UIImageOrientation.Up
        break
    case 3:
        orientation = UIImageOrientation.Down
        break
    case 8:
        orientation = UIImageOrientation.Left
        break
    case 6:
        orientation = UIImageOrientation.Right
        break
    case 2:
        orientation = UIImageOrientation.UpMirrored
        break
    case 4:
        orientation = UIImageOrientation.DownMirrored
        break
    case 5:
        orientation = UIImageOrientation.LeftMirrored
        break
    case 7:
        orientation = UIImageOrientation.RightMirrored
        break
    default:
        break
    }
    return orientation
}

func animatedGIFWithData(data: NSData) -> UIImage? {
    if let source = CGImageSourceCreateWithData(data, nil){
        let count = CGImageSourceGetCount(source)
        
        var animatedImage: UIImage!
        if count <= 1 {
            animatedImage = UIImage(data: data)
        } else {
            var images = [UIImage]()
            var duration: NSTimeInterval = 0.0
            
            for index in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil){
                    duration += frameDurationAdIndex(index, source: source)
                    
                    images.append(UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: .Up))
                }
            }
            
            if duration <= 0.0 {
                duration = (1.0 / 10.0) * Double(count) as NSTimeInterval
            }
            animatedImage = UIImage.animatedImageWithImages(images, duration: duration)
        }
        
        return animatedImage
    }
    return nil
}

func frameDurationAdIndex(index: Int, source: CGImageSourceRef) -> NSTimeInterval {
    var frameDuration: NSTimeInterval = 0.1
    let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as! NSDictionary
    if let gifProperties = frameProperties[kCGImagePropertyGIFDictionary as String] as? NSDictionary {
        if let delay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSTimeInterval {
            frameDuration = delay
        } else {
            if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSTimeInterval {
                frameDuration = delay
            }
        }
    }
    
    if frameDuration < 0.011 {
        frameDuration = 0.1
    }
    
    return frameDuration
}

func contentTypeForImageData(data: NSData) -> String? {
    var value : Int16 = 0
    if data.length >= sizeof(Int16) {
        data.getBytes(&value, length:1)
        
        switch (value) {
        case 0xff:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x49:
            return "image/tiff"
        case 0x4D:
            return "image/tiff"
        case 0x52:
            if (data.length < 12) {
                return nil
            }
            if let temp = NSString(data: data.subdataWithRange(NSMakeRange(0, 12)), encoding: NSASCIIStringEncoding) {
                if (temp.hasPrefix("RIFF") && temp.hasSuffix("WEBP")) {
                    return "image/webp"
                }
            }
            return nil
        default:
            return nil
        }
    }
    else {
        return nil
    }
}

// MARK: - ImageFetcher

enum FetcherResult {
    case Success(image: UIImage, imageData: NSData)
    case Error(error: NSError)
}

class ImageFetcher {
    
    typealias CompeltionClosure = (FetcherResult) -> Void
    
    let imageURL: NSURL
    
    init(imageURL: NSURL) {
        self.imageURL = imageURL
    }
    
    deinit {
        self.completion = nil
    }
    
    var cancelled = false
    
    var completion: CompeltionClosure?
    
    static func fetchImage(url: NSURL, completion: CompeltionClosure?) -> ImageFetcher {
        
        var fetcher: ImageFetcher
        
        if url.fileURL {
            fetcher = DiskImageFetcher(imageURL: url)
        } else {
            fetcher = RemoteImageFetcher(imageURL: url)
        }
        
        fetcher.completion = completion
        
        fetcher.startFetch()
        
        return fetcher
    }
    
    func cancelFetch() {
        self.cancelled = true
    }
    
    func startFetch() {
        fatalError("Subclass need to override this method called: \"startFetch\" ")
    }
    
    final func failedWithError(error: NSError) {
        dispatch_main_async_safe {
            if !self.cancelled {
                if let completionClosure = self.completion {
                    let result = FetcherResult.Error(error: error)
                    completionClosure(result)
                }
            }
        }
    }
    
    final func succeedWithData(imageData: NSData) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [weak self]() -> Void in
            if let strongSelf = self {
                var finalImage: UIImage!
                
                if let image = imageWithData(imageData) {
                    finalImage = scaledImage(image)
                    finalImage = decodedImageWithImage(finalImage)
                    dispatch_main_async_safe {
                        if !strongSelf.cancelled {
                            if let completionClosure = strongSelf.completion {
                                let result = FetcherResult.Success(image: finalImage, imageData: imageData)
                                completionClosure(result)
                            }
                        }
                    }
                } else {
                    let error = NSError(domain: CHUN_ERROR_DOMAIN, code: 404, userInfo: [NSLocalizedDescriptionKey: "create Image with data failed"])
                    strongSelf.failedWithError(error)
                }
            }
            })
    }
}

// MARK: - DiskImageFetcher

class DiskImageFetcher: ImageFetcher {
    
    override func startFetch() {
        self.cancelled = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            if !self.cancelled {
                if let data = NSData(contentsOfURL: self.imageURL) {
                    self.succeedWithData(data)
                } else {
                    let error = NSError(domain: CHUN_ERROR_DOMAIN, code: 404, userInfo: [NSLocalizedDescriptionKey: "No image data fetched from disk"])
                    self.failedWithError(error)
                }
            }
        })
    }
}

// MARK: - RemoteImageFetcher

class RemoteImageFetcher: ImageFetcher {
    
    var session: NSURLSession {
        return NSURLSession.sharedSession()
    }
    
    private var task: NSURLSessionDataTask?
    
    override func startFetch() {
        self.cancelled = false
        
        self.task = self.session.dataTaskWithURL(self.imageURL, completionHandler: { [weak self](data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if let strongSelf = self {
                
                if !strongSelf.cancelled {
                    
                    if let error = error {
                        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                            return
                        }
                        strongSelf.failedWithError(error)
                        return
                    }
                    
                    if let response = response as? NSHTTPURLResponse {
                        if response.statusCode != 200 {
                            let description = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
                            let error = NSError(domain: CHUN_ERROR_DOMAIN, code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: description])
                            strongSelf.failedWithError(error)
                            return
                        } else {
                            let expected = response.expectedContentLength
                            var validateLengthOfData: Bool {
                                if expected > -1 {
                                    if Int64(data!.length) >= expected {
                                        return true
                                    } else {
                                        return false
                                    }
                                }
                                return true
                            }
                            
                            if validateLengthOfData {
                                strongSelf.succeedWithData(data!)
                                return
                            } else {
                                
                                let error = NSError(domain: CHUN_ERROR_DOMAIN, code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Received bytes are not fit with expected"])
                                strongSelf.failedWithError(error)
                                return
                            }
                        }
                    }
                }
            }
            
            })
        
        self.task?.resume()
    }
    
    override func cancelFetch() {
        super.cancelFetch()
        self.task?.cancel()
    }
}

// MARK: - ImageCache

class ImageCache  {
    
    static let fullNamespace = "ImageCache" + CHUN_BASE_DOMAIN
    static let defaultCacheMaxAge: NSTimeInterval = 60 * 60 * 24 * 7; // 1 week
    
    static let basePath: String = {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let hanekePathComponent = fullNamespace
        let basePath = (cachesPath as NSString).stringByAppendingPathComponent(hanekePathComponent)
        return basePath
    }()
    
    var ioQueue: dispatch_queue_t!
    
    var memoryCache: NSCache!
    var fileManager: NSFileManager!
    
    init() {
        
        self.ioQueue = dispatch_queue_create(ImageCache.fullNamespace, nil)
        
        self.memoryCache = NSCache()
        self.memoryCache.name = ImageCache.fullNamespace
        
        dispatch_sync(self.ioQueue) {
            self.fileManager = NSFileManager()
            
            if !self.fileManager.fileExistsAtPath(ImageCache.basePath) {
                do {
                    try self.fileManager.createDirectoryAtPath(ImageCache.basePath, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemory", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAppTerminateNofitication", name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundCleanDisk", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func storeImage(image: UIImage, imageData: NSData, key: String) {
        let cost = Int(image.size.height * image.size.width * image.scale * image.scale)
        self.memoryCache.setObject(image, forKey: key, cost: cost)
        
        self.diskImageExistsWithKey(key, completion: { [weak self](exist, diskURL) -> Void in
            if let strongSelf = self {
                if !exist {
                    dispatch_async(strongSelf.ioQueue) {
                        let diskPath = strongSelf.diskPathForKey(key)
                        strongSelf.fileManager.createFileAtPath(diskPath, contents: imageData, attributes: nil)
                    }
                }
            }
            })
    }
    
    func removeImageWithKey(key: String) {
        self.memoryCache.removeObjectForKey(key)
        
        self.diskImageExistsWithKey(key, completion: { [weak self](exist: Bool, diskURL: NSURL?) -> Void in
            if let strongSelf = self {
                if exist {
                    dispatch_async(strongSelf.ioQueue) {
                        do{
                            try strongSelf.fileManager.removeItemAtURL(diskURL!)
                        }catch _{
                        }
                    }
                }
            }
            })
    }
    
    func diskImageExistsWithKey(key: String, completion: (exist: Bool, diskURL: NSURL?) -> Void) {
        dispatch_async(self.ioQueue) {
            let diskPath = self.diskPathForKey(key)
            let exist = self.fileManager.fileExistsAtPath(diskPath)
            var diskURL: NSURL?
            if exist {
                diskURL = NSURL(fileURLWithPath: diskPath)
            }
            dispatch_main_async_safe {
                completion(exist: exist, diskURL: diskURL)
            }
        }
    }
    
    func imageForMemeoryCacheWithKey(key: String) -> UIImage? {
        return self.memoryCache.objectForKey(key) as? UIImage
    }
    
    @objc func clearMemory() {
        self.memoryCache.removeAllObjects()
    }
    
    func clearDisk(completion: ()-> Void) {
        dispatch_async(self.ioQueue) {
            do {
                try self.fileManager.removeItemAtPath(ImageCache.basePath)
            } catch _ {
            }
            do {
                try self.fileManager.createDirectoryAtPath(ImageCache.basePath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
            dispatch_main_async_safe {
                completion()
            }
        }
    }
    
    @objc private func handleAppTerminateNofitication() {
        self.cleanDisk {}
    }
    
    @objc private func backgroundCleanDisk() {
        
        let application = UIApplication.sharedApplication()
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = application.beginBackgroundTaskWithExpirationHandler {
            application.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
        
        self.cleanDisk {
            application.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    private func cleanDisk(completion: () -> Void) {
        
        dispatch_async(self.ioQueue) {
            let diskCacheURL = NSURL.fileURLWithPath(ImageCache.basePath)
            let resourceKeys = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
            let fileEnumerator = self.fileManager.enumeratorAtURL(diskCacheURL, includingPropertiesForKeys: resourceKeys, options: .SkipsHiddenFiles, errorHandler: nil)
            let expirationDate = NSDate(timeIntervalSinceNow: ImageCache.defaultCacheMaxAge)
            
            var cacheFiles = [NSURL: AnyObject]()
            var currentCacheSize: Int = 0
            var urlsToDelete = [NSURL]()
            
            for fileURL in fileEnumerator!.allObjects {
                if let fileURL = fileURL as? NSURL {
                    if var resourceValues = try? fileURL.resourceValuesForKeys(resourceKeys) {
                        let isDir = resourceValues[NSURLIsDirectoryKey] as! Bool
                        if isDir {
                            continue
                        }
                        let modificationDate = resourceValues[NSURLContentModificationDateKey] as! NSDate
                        
                        if modificationDate.laterDate(expirationDate).isEqualToDate(expirationDate) {
                            urlsToDelete.append(fileURL)
                            continue
                        }
                        let totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey] as! Int
                        currentCacheSize += totalAllocatedSize
                        cacheFiles[fileURL] = resourceValues
                    }
                }
            }
            
            for fileUrl in urlsToDelete {
                do {
                    try self.fileManager.removeItemAtURL(fileUrl)
                } catch _ {
                }
            }
            
            dispatch_main_async_safe(completion)
        }
    }
    
    private func diskPathForKey(key: String) -> String {
        return (ImageCache.basePath as NSString).stringByAppendingPathComponent(self.cacheFileNameForKey(key))
    }
    
    private func cacheFileNameForKey(key: String) -> String {
        return md5String(key)
    }
}


