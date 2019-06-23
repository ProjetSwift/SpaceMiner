import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Charge le menu de démarrage
        let scene = MenuScene(size: CGSize(width: 667, height: 375))
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        skView.presentScene(scene)
        
            
 
    }
    override var shouldAutorotate: Bool {  //Empeche l'écran de tourner
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
