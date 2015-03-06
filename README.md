###Chun Web Image
***

This library provides UIImageView extensions with support for remote images coming from the web. Writen by Swift.

####Main Features

* async download = support for asynchronous downloads directly into the library
* backgr decompr = image decompression executed on a background queue/thread
* store decompr = images are stored in their decompressed version
* memory/disk cache = support for memory/disk cache
* UIImageView extensions = extensions for UIImageView directly into the library

#### Requirements

- iOS 7.0+ / Mac OS X 10.9+
- Xcode 6.3 & Swift 1.2

####Example

	imageView.setImageWithURL(imageURL, placeholderImage: image)

#### Public APIs

	extension UIImageView {

	    /**
	    Set the imageView image with image url.
	    We will fetch and cache the image asynchronous.
	    
	    :param: url the local or remote url for the image
	    */
	    func setImageWithURL(url: NSURL)
	
	    /**
	    Set the imageView image with the image url
	    Before the url image load, will display placeholderImage
	    
	    :param: url the local or remote url for the image
	    :param: placeholderImage the image to be set initially
	    */
	    func setImageWithURL(url: NSURL, placeholderImage: UIImage?)
	}

	class Chun {

	    /// Shared instance to manage the web image fetch and cache
	    class var shared: Chun.Chun { get }
	
	    /**
	    Cancel and remove all fetch
	    */
	    func destroyAllFetch()
	
	    /**
	    Fetch image with local or remote url
	    
	    :param: url      the image url
	    :param: complete callback when the fetch comlete
	    */
	    func fetchImageWithURL(url: NSURL, complete: (Chun.Result) -> Void)
	
	    /**
	    cancel fetch with image url
	    
	    :param: url the url witch waht to cancel
	    */
	    func cancelFetchWithURL(url: NSURL)
	
	    /**
	    Clear all cached image files in the disk
	    */
	    func clearDisk()
	
	    /**
	    Clear all cached images in the memory
	    */
	    func clearMemory()
	}

	enum Result {
	    case Success(image: UIImage, fetchedImageURL: NSURL)
	    case Error(error: NSError)
	}


#### Authors and License

* All source code is licensed under the MIT License.
* Copyright (c) 2014-2015, [@Chun Ye](http://chun.tips)


