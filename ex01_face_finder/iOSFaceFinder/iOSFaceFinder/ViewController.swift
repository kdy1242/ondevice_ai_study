//
//  ViewController.swift
//  iOSFaceFinder
//
//  Created by 공도윤 on 2/19/25.
//

import UIKit
import MLKitFaceDetection
import MLKitVision

class ViewController: UIViewController {
    @IBAction func buttonPressed(_ sender: Any) {
        runFaceContourDetection(with: imageView.image!)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        imageView.image = UIImage(named: "face-test-3")
        imageView.addSubview(annotationOverlayView)
        
        
        NSLayoutConstraint.activate([
          annotationOverlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
          annotationOverlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
          annotationOverlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
          annotationOverlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }
    
    private lazy var faceDetectorOption: FaceDetectorOptions = {
        let option = FaceDetectorOptions()
        option.contourMode = .all
        option.performanceMode = .fast
        return option
    }()
    
    private lazy var annotationOverlayView: UIView = {
        precondition(isViewLoaded)
        let annotationOverlayView = UIView(frame: .zero)
        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        return annotationOverlayView
    }()
    
    
    
    private lazy var faceDetector = FaceDetector.faceDetector(options: faceDetectorOption)
    
    func runFaceContourDetection(with image: UIImage) {
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        faceDetector.process(visionImage) { features, error in
            self.processResult(from: features, error: error)
        }
    }
    
    func processResult(from faces: [Face]?, error: Error?) {
       guard let faces = faces else {
         return
       }
       for feature in faces {
         let transform = self.transformMatrix()
         let transformedRect = feature.frame.applying(transform)
         self.addRectangle(
           transformedRect,
           to: self.annotationOverlayView,
           color: UIColor.green
         )
       }
   }

    private func transformMatrix() -> CGAffineTransform {
      guard let image = imageView.image else { return CGAffineTransform() }
      let imageViewWidth = imageView.frame.size.width
      let imageViewHeight = imageView.frame.size.height
      let imageWidth = image.size.width
      let imageHeight = image.size.height

      let imageViewAspectRatio = imageViewWidth / imageViewHeight
      let imageAspectRatio = imageWidth / imageHeight
      let scale =
        (imageViewAspectRatio > imageAspectRatio)
        ? imageViewHeight / imageHeight : imageViewWidth / imageWidth

      let scaledImageWidth = imageWidth * scale
      let scaledImageHeight = imageHeight * scale
      let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
      let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)

      var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
      transform = transform.scaledBy(x: scale, y: scale)
      return transform
    }
    
    private func addRectangle(_ rectangle: CGRect, to view: UIView, color: UIColor) {
      let rectangleView = UIView(frame: rectangle)
      rectangleView.layer.cornerRadius = 10.0
      rectangleView.alpha = 0.3
      rectangleView.backgroundColor = color
      view.addSubview(rectangleView)
    }
}

