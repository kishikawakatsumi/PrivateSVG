import UIKit

class ViewController: UIViewController {
  @IBOutlet var imageView: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Load SVG data
    let url = Bundle.main.url(forResource: "Swift_logo_horz_lockup_color_rgb", withExtension: "svg")!
    let data = try! Data(contentsOf: url)

    // Use dlopen/dlsym to access Private Framework APIs
    do {
      // Open the CoreSVG private framework
      let path = "/System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG"
      guard let h = dlopen(path, RTLD_NOW) else {
        fatalError(String(cString: dlerror()))
      }

      // Define a placeholder class for CGSVGDocument
      @objc class CGSVGDocument: NSObject {}

      // Get the CGSVGDocumentCreateFromData function
      typealias CreateFn = @convention(c) (CFData?, CFDictionary?) -> Unmanaged<CGSVGDocument>?
      guard let p = dlsym(h, "CGSVGDocumentCreateFromData") else {
        fatalError(String(cString: dlerror()))
      }
      let CGSVGDocumentCreateFromData = unsafeBitCast(p, to: CreateFn.self)

      // Create a CGSVGDocument from the SVG data
      let document = CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue()
      guard let document else { return }

      // Use a private UIImage initializer to create a UIImage from the CGSVGDocument
      let sel = NSSelectorFromString("_imageWithCGSVGDocument:")
      typealias IMPFn =
      @convention(c) (AnyObject, Selector, CGSVGDocument) -> UIImage
      if let imp = (UIImage.self as AnyObject).method(for: sel) {
        do {
          let makeImage = unsafeBitCast(imp, to: IMPFn.self)
          let image = makeImage(UIImage.self, sel, document)

          imageView.image = image
        }
      }

      // Alternatively, manually render the SVG into a CGContext
      typealias DrawFn = @convention(c) (CGContext?, CGSVGDocument?) -> Void
      guard let p = dlsym(h, "CGContextDrawSVGDocument") else {
        fatalError(String(cString: dlerror()))
      }
      let CGContextDrawSVGDocument = unsafeBitCast(p, to: DrawFn.self)

      let size = CGSize(width: 191.19, height: 59.39)
      let render = UIGraphicsImageRenderer(size: size)
      let image = render.image { (context) in
        let cgContext = context.cgContext
        cgContext.translateBy(x: 0, y: size.height)
        cgContext.scaleBy(x: 1, y: -1)
        CGContextDrawSVGDocument(cgContext, document)
      }

      imageView.image = image
    }

    // Uncomment to use CFBundle APIs instead of dlopen/dlsym
  
    // do {
    //   let path = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/CoreSVG.framework")
    //   guard let cf = CFBundleCreate(kCFAllocatorDefault, path as CFURL) else {
    //     return
    //   }

    //   guard CFBundleLoadExecutable(cf) else {
    //     return
    //   }

    //   @objc class CGSVGDocument: NSObject {}

    //   typealias CreateFn =
    //   @convention(c) (CFData?, CFDictionary?) -> Unmanaged<CGSVGDocument>?

    //   guard let p = CFBundleGetFunctionPointerForName(cf, "CGSVGDocumentCreateFromData" as CFString) else {
    //     return
    //   }
    //   let CGSVGDocumentCreateFromData: CreateFn = unsafeBitCast(p, to: CreateFn.self)

    //   let document =
    //   CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue()

    //   typealias DrawFn = @convention(c) (CGContext?, CGSVGDocument?) -> Void

    //   guard let p = CFBundleGetFunctionPointerForName(cf, "CGContextDrawSVGDocument" as CFString) else {
    //     return
    //   }
    //   let CGContextDrawSVGDocument: DrawFn = unsafeBitCast(p, to: DrawFn.self)

    //   let size = CGSize(width: 191.19, height: 59.39)
    //   let renderer = UIGraphicsImageRenderer(size: size)
    //   let image = renderer.image { ctx in
    //     guard let document = document else { return }
    //     let cg = ctx.cgContext
    //     cg.translateBy(x: 0, y: size.height)
    //     cg.scaleBy(x: 1, y: -1)
    //     CGContextDrawSVGDocument(cg, document)
    //   }

    //   imageView.image = image
    // }
  }
}
