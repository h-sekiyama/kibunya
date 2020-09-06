import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation
import FirebaseUI

class ChangeNameViewController: UIViewController, UITextFieldDelegate {
    
    //ストレージサーバのURLを取得
    let storage = Storage.storage().reference(forURL: "gs://kibunya-app.appspot.com")
    //保存したい画像のデータを変数として持つ
    var ProfileImageData: Data = Data()
    // 自分のUID
    var myUserId: String = ""
    
    // タブ定義
    var tabBarView: TabBarView!
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // プロフィールアイコン画像
    @IBOutlet weak var profileIcon: UIImageView!
    @IBAction func profileIconTap(_ sender: UITapGestureRecognizer) {
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ipc.sourceType = UIImagePickerController.SourceType.photoLibrary
        //編集を可能にする
        ipc.allowsEditing = true
        self.present(ipc,animated: true, completion: nil)
    }
    
    // 名前入力テキストボックス
    @IBOutlet weak var nameTextBox: UITextField!
    // プロフィール変更ボタン
    @IBOutlet weak var updateProfile: UIButton!
    @IBAction func updateProfile(_ sender: Any) {
        startIndicator()

        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = nameTextBox.text
        changeRequest?.commitChanges { (error) in
            if (error != nil) {
                self.changeCompleteLabel.isHidden = true
                return
            }
            
            self.defaultStore.collection("users").document(self.myUserId).updateData(["name": self.nameTextBox.text!]) { err in
                if let err  = err {
                    print("Error update document: \(err)")
                    self.changeCompleteLabel.isHidden = true
                }else{
                    self.changeCompleteLabel.isHidden = false
                }
            }
            
            self.dismissIndicator()
        }
        
        uploadImage()
    }
    
    // プロフィールアイコンの更新処理
    func uploadImage () {
        //保存したい画像のデータを変数として持つ
        var ProfileImageData: Data = Data()
        //プロフィール画像が存在すれば
        if (profileIcon.image != UIImage(named: "no_image")!) {
            //画像を圧縮
            ProfileImageData = (profileIcon.image?.jpegData(compressionQuality: 0.01))!
            let imageRef = storage.child("profileIcon").child("\(myUserId).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            //storageに画像を送信
            imageRef.putData(ProfileImageData, metadata: metadata) { (metaData, error) in
                //エラーであれば
                if error != nil {
                    print(error.debugDescription)
                    return
                }
                self.updateProfile.isEnabled = false
            }
        }
    }
    
    // 変更完了ラベル
    @IBOutlet weak var changeCompleteLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定済みの名前をテキストフィールドに表示
        Auth.auth().currentUser?.reload()
        guard let name = Auth.auth().currentUser?.displayName else {
            return
        }
        nameTextBox.text = name
        nameTextBox.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        myUserId = Auth.auth().currentUser?.uid ?? ""
        let imageRef = storage.child("profileIcon").child("\(myUserId).jpg")
        imageRef.downloadURL(completion: { [weak self] url, error in
            guard let self = self else { return }
            if error != nil {
                print(error!.localizedDescription)
            }
            guard let url = url else { return }
            
            //
            self.profileIcon.sd_setImage(with: url)
        })
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self

        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - 80, width: self.view.bounds.width, height: 80)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする。
        if(nameTextBox.isFirstResponder) {
            nameTextBox.resignFirstResponder()
        }
    }
    
    // 各テキストフィールド入力監視
    @objc func textFieldDidChange(_ textFiled: UITextField) {
        if (nameTextBox.text!.count > 0) {
            updateProfile.isEnabled = true
        } else {
            updateProfile.isEnabled = false
        }
    }
}

extension ChangeNameViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileIcon.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileIcon.image = originalImage
        }
        dismiss(animated: true, completion: nil)
        updateProfile.isEnabled = true
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
