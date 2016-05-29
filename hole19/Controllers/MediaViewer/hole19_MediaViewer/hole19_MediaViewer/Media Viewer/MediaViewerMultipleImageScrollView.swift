
import UIKit


@objc protocol MediaViewerMultipleImageScrollViewActionsDelegate: class {
    func scrollViewScrolledToImageModel(image: MediaViewerImage?)
}

class MediaViewerMultipleImageScrollView: UIView {
    
    // MARK: properties

    var scrollView: UIScrollView!

    var contentViews = [MediaViewerInteractiveImageView]()
    
    weak var mediaViewerDelegate: MediaViewerDelegate?
    weak var scrollDelegate: MediaViewerMultipleImageScrollViewActionsDelegate?

    var imageViewActionsDelgate: MediaViewerInteractiveImageViewDelegate? {
        didSet {
            setDelegateForAllViews(contentViews)
        }
    }
    var singleTapGestureRecogniserThatReqiresFailure: UITapGestureRecognizer? {
        didSet {
            setRecogniserRequiredToFailWithView(currentImageView())
        }
    }
    
    var images: [MediaViewerImage]? {
        didSet {
            guard let images = images else { return }
            var selected = selectedImage
            if selected == nil {
                selected = images.first
            }
            updateViewWithImages(images, selectedImage: selected!)
        }
    }
    var selectedImage: MediaViewerImage?
    var currentPage: Int = 0
    let inbetweenImagesMargin: CGFloat = 4.0
    
    private var hiddenImageView = UIImageView()
    
    // MARK: init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(contentViews.count), height: bounds.size.height)
        var currentViewFrame = CGRect(x: inbetweenImagesMargin, y: 0.0, width: bounds.size.width, height: scrollView.bounds.size.height)
        for image in contentViews {
            image.frame = currentViewFrame
            currentViewFrame.origin.x += scrollView.bounds.size.width
        }
        scrollView.contentOffset = CGPoint(x:CGFloat(currentPage)*scrollView.bounds.size.width, y:0.0)
}

    // MARK: public
    
    func currentImageView() -> MediaViewerInteractiveImageView? {
        if currentPage < contentViews.count {
            return contentViews[currentPage]
        }
        return nil
    }
    
    func zoomOut() {
        if let currentTopView = currentImageView() {
            currentTopView.zoomOut()
        }
    }

    func setImages(images: [MediaViewerImage], withSelectedOne selImage: MediaViewerImage) {
        removeAllCurrentContents()
        self.selectedImage = selImage
        self.images = images
    }
    
    // MARK: private
    
    private func setupView() {
        setupScrollView()
        backgroundColor = UIColor.clearColor()
    }

    private func setupScrollView() {
        var frame = bounds
        frame.origin.x -= inbetweenImagesMargin
        frame.size.width += inbetweenImagesMargin*2.0
        scrollView = UIScrollView(frame: frame)
        scrollView.clipsToBounds = false
        scrollView.userInteractionEnabled = true
        scrollView.pagingEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        self.addSubviewAndFullScreenConstraints(scrollView, sideMargins: -inbetweenImagesMargin)
    }

    private func updateViewWithImages(newImages: [MediaViewerImage], selectedImage: MediaViewerImage) {
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(newImages.count), height: bounds.size.height)
        var currentViewFrame = scrollView.bounds
        currentViewFrame.origin.x = inbetweenImagesMargin
        currentViewFrame.size.width = bounds.width
        for image in newImages {
            let contentView = contentViewWithImageModel(image, frame: currentViewFrame)
            contentViews.append(contentView)
            currentViewFrame.origin.x += scrollView.bounds.size.width
        }
        if let mediaViewerDelegate = mediaViewerDelegate, let hasMoreToLoad = mediaViewerDelegate.hasMoreImagesToLoad?(newImages) {
            if hasMoreToLoad {
                let contentView = contentViewWithImageModel(nil, frame: currentViewFrame)
                contentView.activityIndicator.startAnimating()
                contentView.activityIndicator.hidden = false
                contentViews.append(contentView)
            }
        }
        setRecogniserRequiredToFailWithView(currentImageView())
        setDelegateForAllViews(contentViews)
        if let index = newImages.indexOf(selectedImage) {
            scrollView.contentOffset = CGPoint(x:CGFloat(index)*scrollView.bounds.size.width, y:0.0)
            currentPage = index
            if let hiddentImageView = mediaViewerDelegate?.imageViewForImage(newImages[index]) {
                self.hiddenImageView = hiddentImageView
            }
        }
    }
    
    private func contentViewWithImageModel(imageModel: MediaViewerImage?, frame: CGRect) -> MediaViewerInteractiveImageView {
        let contentView = MediaViewerInteractiveImageView(frame: frame)
        contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        contentView.imageModel = imageModel
        scrollView.addSubview(contentView)

        return contentView
    }
    
    private func updateViewWithCurrentPage(currentPageIndex: Int) {
        let currentView = contentViews[currentPageIndex]
        setRecogniserRequiredToFailWithView(currentView)
    }
    
    private func setRecogniserRequiredToFailWithView(imageView: MediaViewerInteractiveImageView?) {
        guard let imageView = imageView else { return }
        
        if let rec = singleTapGestureRecogniserThatReqiresFailure {
            rec.requireGestureRecognizerToFail(imageView.zoomDoubleTapGestureRecogniser)
        }
    }
    
    private func setDelegateForAllViews(allViews: [MediaViewerInteractiveImageView]) {
        if let imageViewActionsDelgate = imageViewActionsDelgate {
            for view in allViews {
                view.delegate = imageViewActionsDelgate
            }
        }
    }
    
    private func scrollImageViewContainerToCorrespondingImage(index: Int) {
        if let mediaViewerDelegate = mediaViewerDelegate {
            if let collectionView = mediaViewerDelegate.scrollImageviewsContainer() as? UICollectionView {
                collectionView.scrollToItemWithIndex(index)
            }
        }
    }
    
    private func hideCorrespondingImage(index: Int) {
        hiddenImageView.hidden = false
        if let mediaViewerDelegate = mediaViewerDelegate,
            let images = images where images.count > index {
            if let hiddentImageView = mediaViewerDelegate.imageViewForImage(images[index]) {
                self.hiddenImageView = hiddentImageView
                hiddentImageView.hidden = true
            }
        }
    }
    
    private func zoomOutAllViewsButCurrentAtIndex(currentIndex: Int) {
        for (index, content) in contentViews.enumerate() {
            if index != currentIndex {
                content.zoomOut(animated: false)
            }
        }
    }
    
    private func askDelegateForMoreImages() {
        guard let images = images else { return }

        mediaViewerDelegate?.loadMoreImages?(withImages: images, completition: { [weak self] (newImages, error) in
            guard let weakSelf = self else { return }
            var newCurrentImages = newImages
            if let currentImages = weakSelf.images {
                newCurrentImages = currentImages
                newCurrentImages.appendContentsOf(newImages)
            }
            var selectedImage = newCurrentImages.first
            if let currentImage = weakSelf.currentImageView()?.imageModel {
                selectedImage = currentImage
            } else if let currentCount = weakSelf.images?.count where newCurrentImages.count > currentCount {
                selectedImage = newCurrentImages[currentCount]
            }
            if let selectedImage = selectedImage {
                weakSelf.setImages(newCurrentImages, withSelectedOne: selectedImage)
                weakSelf.scrollDelegate?.scrollViewScrolledToImageModel(selectedImage)
            }
        })
    }
    
    private func removeAllCurrentContents() {
        for view in contentViews {
            view.removeFromSuperview()
        }
        contentViews = [MediaViewerInteractiveImageView]()
        scrollView.contentSize = CGSizeZero
        scrollView.contentOffset = CGPointZero
    }
}

extension MediaViewerMultipleImageScrollView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        updateViewWithCurrentPage(currentPage)
        scrollImageViewContainerToCorrespondingImage(currentPage)
        hideCorrespondingImage(currentPage)
        if let images = images where images.count > currentPage {
            scrollDelegate?.scrollViewScrolledToImageModel(images[currentPage])
        } else {
            scrollDelegate?.scrollViewScrolledToImageModel(nil)
            askDelegateForMoreImages()
        }
        zoomOutAllViewsButCurrentAtIndex(currentPage)
    }
}