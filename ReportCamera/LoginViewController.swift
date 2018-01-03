//
//  LoginViewController.swift
//  ReportCamera
//
//  Created by tanaka.takaaki on 2017/02/05.
//  Copyright © 2017年 tanaka.takaaki. All rights reserved.
//

import UIKit
import AWSCognito
import AWSCore
import TwitterKit

class TwitterProvider: NSObject, AWSIdentityProviderManager {
    /**
     Each entry in logins represents a single login with an identity provider. The key is the domain of the login provider (e.g. 'graph.facebook.com') and the value is the OAuth/OpenId Connect token that results from an authentication with that login provider.
     */
    var tokens : [NSString : NSString]?
    
    init(tokens: [NSString : NSString]) {
        self.tokens = tokens
    }
    
    public func logins() -> AWSTask<NSDictionary> {
        
        let token: NSDictionary = NSDictionary(dictionary: tokens!)
        
        return AWSTask(result: token)
    }
}

class LoginViewController: UIViewController {

    var identityId = ""
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "List" {
            if let vc = segue.destination as? CameraViewController {
                vc.identityId = identityId
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let logInButton = TWTRLogInButton { (session, error) in
            if let unwrappedSession = session {
                let alert = UIAlertController(title: "Logged In",
                                              message: "User \(unwrappedSession.userName) has logged in",
                    preferredStyle: UIAlertControllerStyle.alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                //self.present(alert, animated: true, completion: nil)
                
                let value = unwrappedSession.authToken + ";" + unwrappedSession.authTokenSecret
                // Note: This overrides any existing logins
                
                let provider = TwitterProvider(tokens: ["api.twitter.com": value as NSString])
                
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APNortheast1,
                                                                        identityPoolId: "pool-id",
                                                                        identityProviderManager: provider)
                
                let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider:credentialsProvider)
                
                AWSServiceManager.default().defaultServiceConfiguration = configuration
                
               
                credentialsProvider.getIdentityId().continueOnSuccessWith(block: { [weak self] task -> Any? in
                    print(credentialsProvider.identityId)
                    
                    if credentialsProvider.identityId != nil {
                        self?.performSegue(withIdentifier: "List", sender: nil)
                    }
                    return nil
                })
                
                
            } else {
                NSLog("Login error: %@", error!.localizedDescription);
            }
        }
        
        // TODO: Change where the log in button is positioned in your view
       if let button = logInButton {
            logInButton.center = self.view.center
            self.view.addSubview(logInButton)
       }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
