
import UIKit

class MediaViewerMultipleImageScrollView: UIView {
    
    // MARK: properties

    var scrollView: UIScrollView!

    var contentViews = [MediaViewerInteractiveImageView]()
    
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
    
    var images: [UIImage]? {
        didSet {
            guard let images = images else { return }
            updateViewWithImages(images)
        }
    }
    var currentPage: Int = 0
    
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
        scrollView.contentSize = CGSize(width: bounds.size.width * CGFloat(contentViews.count), height: bounds.size.height)
        var currentViewFrame = scrollView.bounds
        for image in contentViews {
            image.frame = currentViewFrame
            currentViewFrame.origin.x += scrollView.bounds.size.width
        }
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

    // MARK: private
    
    private func setupView() {
        setupScrollView()
        backgroundColor = UIColor.clearColor()
    }

    private func setupScrollView() {
        scrollView = UIScrollView(frame: bounds)
        scrollView.clipsToBounds = false
        scrollView.userInteractionEnabled = true
        scrollView.pagingEnabled = true
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        self.addSubviewAndFullScreenConstraints(scrollView)
    }

    private func updateViewWithImages(newImages: [UIImage]) {
        scrollView.contentSize = CGSize(width: bounds.size.width * CGFloat(newImages.count), height: bounds.size.height)
        var currentViewFrame = scrollView.bounds
        for image in newImages {
            let contentView = MediaViewerInteractiveImageView(frame: currentViewFrame)
            contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            contentView.imageView.image = image
            contentViews.append(contentView)
            scrollView.addSubview(contentView)
            currentViewFrame.origin.x += currentViewFrame.size.width
        }
        setRecogniserRequiredToFailWithView(currentImageView())
        setDelegateForAllViews(contentViews)
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
}

extension MediaViewerMultipleImageScrollView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        updateViewWithCurrentPage(currentPage)
    }
}
