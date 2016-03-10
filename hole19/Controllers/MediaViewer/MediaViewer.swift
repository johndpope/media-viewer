
import UIKit
import SDWebImage

class MediaViewer: UIViewController {
    
    // MARK: properties
    
    var mediaURL = NSURL()
    var sourceImageView: UIImageView?
    
    var transitionAnimator: MediaViewerTransitionAnimator?
    
    var contentsView: MediaViewerContentsView!
    
    // MARK: init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(mediaURL: NSURL, sourceImageView: UIImageView) {
        self.init(nibName: nil, bundle: nil)
        self.mediaURL = mediaURL
        self.sourceImageView = sourceImageView
        modalPresentationStyle = .OverCurrentContext
    }

    // MARK: UIViewController
    
    override func loadView() {
        super.loadView()
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if transitionAnimator == nil, let sourceImageView = sourceImageView {
            transitionAnimator = MediaViewerTransitionAnimator(sourceImageView: sourceImageView, contentsView: contentsView)
        }
        contentsView.imageView.sd_setImageWithURL(mediaURL)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        transitionAnimator?.transitionToDestinationImageView(true)
    }
    
    // MARK: public
    
    func close(sender: UIButton) {
        transitionAnimator?.transitionBackToSourceImageView(true, withCompletition: { [weak self] in
            self?.dismissViewControllerAnimated(false, completion: nil)
        })
    }
    
    // MARK: private
    
    private func setupView() {
        setupContentsView()
        setupCloseButton()
        view.backgroundColor = UIColor.clearColor()
    }
    
    private func setupContentsView() {
        contentsView = MediaViewerContentsView(frame: CGRectZero)
        addSubviewAndFullScreenConstraints(contentsView)
    }
    
    private func setupCloseButton() {
        contentsView.closeButton.addTarget(self, action: "close:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func addSubviewAndFullScreenConstraints(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[subview]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["subview" : subview]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[subview]|", options: NSLayoutFormatOptions.AlignAllLeft, metrics: nil, views: ["subview" : subview]))
    }
}