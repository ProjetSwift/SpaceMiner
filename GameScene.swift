import CoreMotion
import SpriteKit

enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")

    //lecture des fichiers de vagues et d'ennemis
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")

    var JoueurEnVie = true
    var levelNumber = 0
    var waveNumber = 0
    var timer = Timer()  //initialisation du timer pour le tir joueur
    
    lazy var VieLabel: SKLabelNode = {  //Permet d'afficher la vie
        var label = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        label.fontSize = CGFloat.init(32)
        label.zPosition = 2
        label.fontColor = SKColor.white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .bottom
        label.text = "0 PV"
        return label
    }()
    
    lazy var scoreLabel: SKLabelNode = {  //Permet d'afficher le score
        var label = SKLabelNode(fontNamed: "GurmukhiMN-Bold")
        label.fontSize = CGFloat.init(32)
        label.zPosition = 2
        label.fontColor = SKColor.white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .bottom
        label.text = "Score 0"
        return label
    }()
    
    
    var Vie = 0
    var VieStartValue = 20
    var score = 0
    var scoreStartValue = 0
   
    //Array des positions autorisées selon y pour les ennemis
    let positions = Array(stride(from: 0, through: 320, by: 40))

    
    //didMove est la partie dans laquelle on crée le contenu de la scène
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        if let particules = SKEmitterNode(fileNamed: "Starfield") {
            particules.position = CGPoint(x: 1080, y: 0)
            particules.advanceSimulationTime(60)
            particules.zPosition = -1
            addChild(particules)
        }
        
        
        //Permet de lancer la fonction SpawnBullets à un interval spécifique
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector : #selector(SpawnBullets), userInfo: nil, repeats: true)

        //Initialisationd de la position du player
        player.name = "player"
        player.position.x = 75
        player.position.y = 187.5
        player.zPosition = 1
        addChild(player)
        
        //On donne les caractéristiques de collision au player
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false

        
        //affichage de la vie
        VieLabel.position = CGPoint(x: 20, y: 20)
        addChild(VieLabel)
        Vie = VieStartValue
        
        scoreLabel.position = CGPoint(x: 500, y: 20)
        addChild(scoreLabel)
        score = scoreStartValue
        
    }
    
    //Fonction pour faire tirer le joueur
    @objc func SpawnBullets(){
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position
        
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        addChild(shot)
        
        let movement = SKAction.move(to: CGPoint(x: 1900, y: shot.position.y), duration: 5)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        shot.run(sequence)
    }
    
    
    //update va exécuter ses lignes de code à chaque nouvelle frame
    override func update(_ currentTime: TimeInterval) {
        guard JoueurEnVie else { return } //On vérifie que le joueur est en vie
        
        //supprime les ennemis dès qu'ils dépassent l'écran
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }

        let activeEnemies = children.compactMap { $0 as? EnemyNode }

        if activeEnemies.isEmpty {
            createWave()
        }

        for enemy in activeEnemies {
            guard frame.intersects(enemy.frame) else { continue }

            if enemy.lastFireTime + 1 < currentTime {
                enemy.lastFireTime = currentTime

                if Int.random(in: 0...6) == 0 {
                    enemy.fire()
                }
            }
        }
        
        //affichage de la vie et du score
        VieLabel.text = "\(Vie) PV"
        scoreLabel.text = "Score \(score)"
    }

    func createWave() {
        guard JoueurEnVie else { return } //vérifie que le joueur est en vie

        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }

        let currentWave = waves[waveNumber]
        waveNumber += 1

        let maximumEnemyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<maximumEnemyType)

        let enemyOffsetX: CGFloat = 100
        let enemyStartX = 600

        if currentWave.enemies.isEmpty {
            for (index, position) in positions.shuffled().enumerated() {
                let enemy = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: position), xOffset: enemyOffsetX * CGFloat(index * 3), moveStraight: true)
                addChild(enemy)
            }
        } else {
            for enemy in currentWave.enemies {
                let node = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), xOffset: enemyOffsetX * enemy.xOffset, moveStraight: enemy.moveStraight)
                addChild(node)
            }
        }
    }
  
    // cette focntion déplace le vaisseau à l'endroit du clic
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            
            player.position.y = location.y
        }
    }
    
    // cette fonction permet de suivre le doigt du joueur
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            
            player.position.y = location.y
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        let sortedNodes = [nodeA, nodeB].sorted { $0.name ?? "" < $1.name ?? "" }
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]

        if secondNode.name == "player" {
            guard JoueurEnVie else { return }

            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = firstNode.position
                addChild(explosion)
            }

            Vie -= 1

            if Vie == 0 {
                gameOver()
                secondNode.removeFromParent()
            }

            firstNode.removeFromParent()
        } else if let enemy = firstNode as? EnemyNode {
            enemy.shields -= 1

            if enemy.shields == 0 {
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemy.position
                    addChild(explosion)
                }

                score += 1
                enemy.removeFromParent()
            }

            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = enemy.position
                addChild(explosion)
            }

            secondNode.removeFromParent()
        } else {
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = secondNode.position
                addChild(explosion)
            }

            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }

    //s'exécute quand le joueur meurt
    func gameOver() {
        JoueurEnVie = false

        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = player.position
            addChild(explosion)
        }

        let gameOver = SKSpriteNode(imageNamed: "gameOver2")
        gameOver.position = CGPoint(x: 333.5, y: 187.5)
        addChild(gameOver)
        
        timer.invalidate()  //Stoppe le timer et les tirs du player
        VieLabel.removeFromParent() //supprime l'affichage de la vie
        
        
    }
}
