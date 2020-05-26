//
//  FocusEntity.swift
//
//
//  Created by Dilshod Turobov on 5/18/20.
//

import ARKit
import RealityKit
import Combine

@available(iOS 13, *)
open class FocusSquare: Entity {
    // MARK: - Types
    
    public enum State: Equatable {
        case initializing
        case detecting(raycastResult: ARRaycastResult, camera: ARCamera?)
    }
    
    // MARK: - Properties
    
    /// The most recent position of the focus square based on the current state.
    var lastPosition: SIMD3<Float>? {
        switch state {
        case .initializing: return nil
        case .detecting(let raycastResult, _): return raycastResult.worldTransform.translation
        }
    }
    
    public var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            
            switch state {
            case .initializing:
                displayAsBillboard()
                
            case let .detecting(raycastResult, camera):
                if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
                    displayAsClosed(for: raycastResult, planeAnchor: planeAnchor, camera: camera)
                } else {
                    displayAsOpen(for: raycastResult, camera: camera)
                }
            }
        }
    }
    
    /// The focus square's most recent positions.
    private var recentFocusSquarePositions: [SIMD3<Float>] = []
    /// A counter for managing orientation updates of the focus square.
    private var counterToNextOrientationUpdate: Int = 0
    /// Indicates if the camera is currently pointing towards the floor.
    private var isPointingDownwards = true
    /// Indicates if the square is currently changing its orientation when the camera is pointing downwards.
    private var isChangingOrientation = false
    /// Previously visited plane anchors.
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    /// Indicates if the square is currently being animated for opening or closing.
    private var isAnimating = false
    /// Indicates if the focus square transform is updated automatically
    public private(set) var isAutoUpdating: Bool = false
    /// Indicates if the focus square is hidden
    private var isHidden = false
    
    private var orientationAnimationSub: Cancellable?
    private var sceneSubscription: Cancellable?
    
    public var planeColor = UIColor.blue
    private var plane: ModelEntity
    
    let worldAnchor = AnchorEntity(world: .zero)
    let cameraAnchor = AnchorEntity(.camera)
    
    weak public var arViewDelegate: ARView? {
        didSet {
            self.arViewDelegate?.scene.addAnchor(worldAnchor)
            self.arViewDelegate?.scene.addAnchor(cameraAnchor)
        }
    }
    
    required public init() {
        plane = ModelEntity(mesh: .generatePlane(width: 0.1, depth: 0.1, cornerRadius: 0.01), materials: [SimpleMaterial(color: planeColor, isMetallic: false)])
        
        super.init()
        
        self.addChild(plane)
        displayAsBillboard()
        cameraAnchor.addChild(self)
    }
    
    
    
    public func setAutoUpdate(to autoUpdate: Bool) {
        if autoUpdate {
            subscribeToSceneUpdates()
        } else {
            sceneSubscription?.cancel()
        }
        
        self.isAutoUpdating = autoUpdate
    }
    
    func subscribeToSceneUpdates() {
        sceneSubscription = arViewDelegate?.scene.subscribe(to: SceneEvents.Update.self) { (event) in
            self.updateFocusSquare()
        }
    }
    
    
    
    
    // MARK: - Display methods
    
    /// Displays the focus square parallel to the camera plane.
    private func displayAsBillboard() {
        transform = Transform(matrix: matrix_identity_float4x4)
        transform.rotation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
        position.z = -0.5
        
        unhide()
    }
    
    /// Called when a surface has been detected.
    private func displayAsOpen(for raycastResult: ARRaycastResult, camera: ARCamera?) {
        plane.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
        setPosition(with: raycastResult, camera)
    }
    
    /// Called when a plane has been detected.
    private func displayAsClosed(for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
        plane.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
        anchorsOfVisitedPlanes.insert(planeAnchor)
        setPosition(with: raycastResult, camera)
    }
    
    func setPosition(with raycastResult: ARRaycastResult, _ camera: ARCamera?) {
        let position = raycastResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
        updateTransform(for: raycastResult, camera: camera)
    }
    
    // MARK: - Update methods
    
    public func updateFocusSquare() {
        if let camera = arViewDelegate?.session.currentFrame?.camera, case .normal = camera.trackingState,
            let query = arViewDelegate?.getRaycastQuery(for: .any),
            let result = arViewDelegate?.castRay(for: query).first {
            worldAnchor.addChild(self)
            self.state = .detecting(raycastResult: result, camera: camera)
            
        } else {
            cameraAnchor.addChild(self)
            self.state = .initializing
        }
        
    }
    
    func updateOrientation(basedOn orientation: simd_quatf) {
        if isChangingOrientation {
            return
        }
        isChangingOrientation = true
        
        var transform = self.transform
        transform.rotation = orientation
        
        move(to: transform, relativeTo: parent, duration: 0.2, timingFunction: .easeInOut)
        
        orientationAnimationSub = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self, { (event) in
            self.isChangingOrientation = false
        })
    }
    
    func updateTransform(for raycastResult: ARRaycastResult, camera: ARCamera?) {
        recentFocusSquarePositions = Array(recentFocusSquarePositions.suffix(10))
        
        // Move to average of recent positions to avoid jitter.
        let average = recentFocusSquarePositions.reduce([0, 0, 0], { $0 + $1 }) / Float(recentFocusSquarePositions.count)
        self.position = average
        
        self.scale = [1.0, 1.0, 1.0] * scaleBasedOnDistance(camera: camera)
        
        // Correct y rotation when camera is close to horizontal
        // to avoid jitter due to gimbal lock.
        guard let camera = camera else { return }
        let tilt = abs(camera.eulerAngles.x)
        let threshold: Float = .pi / 2 * 0.75
        var orientation = raycastResult.worldTransform.orientation
        
        if tilt > threshold {
            self.isPointingDownwards = true
            
            let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
            orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
            updateOrientation(basedOn: orientation)
        } else {
            // Update orientation only fource per second to avoid jitter.
            if counterToNextOrientationUpdate == 15 || isPointingDownwards {
                counterToNextOrientationUpdate = 0
                isPointingDownwards = false
                updateOrientation(basedOn: orientation)
            }
            counterToNextOrientationUpdate += 1
        }
    }
    
    /**
     Reduce visual size change with distance by scaling up when close and down when far away.
     
     These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
     (estimated distance when looking at a table), and a scale of 1.2x
     for a distance 1.5 m distance (estimated distance when looking at the floor).
     */
    private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }
        
        let distanceFromCamera = simd_length(position(relativeTo: nil) - camera.transform.translation)
        //        print(distanceFromCamera)
        if distanceFromCamera < 0.7 {
            return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
        }
    }
    
    // MARK: - Animation utlities
    
    func runTimer(duration: Double, completion: @escaping (_ percentage: CGFloat) -> Void) {
        let startTime = Date().timeIntervalSince1970
        let endTime = duration + startTime
        
        Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { (timer) in
            let now = Date().timeIntervalSince1970
            
            if now > endTime {
                timer.invalidate()
                self.isAnimating = false
                return
            }
            let percentage = CGFloat((now - startTime) / duration)
            completion(percentage)
            
        }
    }
    
    func hide() {
        if isAnimating || isHidden {
            return
        }
        isAnimating = true
        isHidden = true
        runTimer(duration: 0.2) { (percentage) in
            let color = self.planeColor.withAlphaComponent(1 - percentage)
            var material: Material = SimpleMaterial(color: color, isMetallic: false)
            if percentage >= 0.9 {
                material = OcclusionMaterial()
            }
            self.plane.model?.materials = [material]
        }
    }
    
    func unhide() {
        if isAnimating || !isHidden {
            return
        }
        isAnimating = true
        isHidden = false
        runTimer(duration: 0.2) { (percentage) in
            let color = self.planeColor.withAlphaComponent(percentage)
            let material: Material = SimpleMaterial(color: color, isMetallic: false)
            
            self.plane.model?.materials = [material]
        }
    }
}
