import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation
import CropViewController
import FirebaseUI

class InputKibunViewController: UIViewController {
    //ストレージサーバのURLを取得
    let storage = Storage.storage().reference(forURL: "gs://kibunya-app.appspot.com")
    // タブ定義
    var tabBarView: TabBarView!
    // FireStore取得
    let defaultStore: Firestore! = Firestore.firestore()
    // 気分ボタンを入れる配列
    var kibunButtonArray: [UIButton] = []
    // 気分情報を入れる変数
    var kibunStatus: Int? = nil {
        didSet {
            if kibunStatus == nil {
                return
            }
            for (index, kibunButton) in kibunButtonArray.enumerated() {
                kibunButton.setImage(UIImage(named: "kibunIcon\(index)_off"), for: .normal)
            }
            kibunButtonArray[kibunStatus!].setImage(UIImage(named: "kibunIcon\(kibunStatus!)"), for: .normal)
        }
    }
    
    // 画像を添付したかどうか
    var isExistImage: Bool = false
    // 今日あった出来事を入力するテキストボックス
    @IBOutlet weak var kibunTextBox: UITextView!
    
    // 最高ボタンタップ
    @IBOutlet weak var kibunButton0: UIButton!
    @IBAction func kibunButton0(_ sender: Any) {
        kibunStatus = 0
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        }
    }
    // 良いボタンタップ
    @IBOutlet weak var kibunButton1: UIButton!
    @IBAction func kibunButton1(_ sender: Any) {
        kibunStatus = 1
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        }
    }
    // 普通ボタンタップ
    @IBOutlet weak var kibunButton2: UIButton!
    @IBAction func kibunButton2(_ sender: Any) {
        kibunStatus = 2
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        }
    }
    // 悪いボタンタップ
    @IBOutlet weak var kibunButton3: UIButton!
    @IBAction func kibunButton3(_ sender: Any) {
        kibunStatus = 3
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        }
    }
    // 最悪ボタンタップ
    @IBOutlet weak var kibunButton4: UIButton!
    @IBAction func kibunButton4(_ sender: Any) {
        kibunStatus = 4
        if (kibunTextBox.text?.count != 0) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        }
    }
    // 送信ボタン
    @IBOutlet weak var sendButton: UIButton!
    // 送信ボタンタップ
    @IBAction func sendButton(_ sender: Any) {
        if (kibunTextBox.text.count == 0) {
            sendKibunCompleteLabel.text = "気分が未入力です"
            sendKibunCompleteLabel.isHidden = false
        } else {
            startIndicator()
            updateData()
        }
    }
    // 吹き出し表示用View
    @IBOutlet weak var balloonView: UIView!
    // 残り入力可能文字数
    @IBOutlet weak var remainingTextCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // テキストボックス入力監視
        kibunTextBox.delegate = self
        
        // 気分ボタンを配列に入れる
        kibunButtonArray = [kibunButton0, kibunButton1, kibunButton2, kibunButton3, kibunButton4]
    }
    
    // 画像添付ボタン
    @IBOutlet weak var sendImage: UIImageView!
    @IBAction func sendImage(_ sender: Any) {
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ipc.sourceType = UIImagePickerController.SourceType.photoLibrary
        ipc.modalPresentationStyle = .fullScreen
        self.present(ipc,animated: true, completion: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        // タブの表示
        tabBarView  = TabBarView()
        view.addSubview(tabBarView.tab)
        tabBarView.owner = self

        // タブの表示位置を調整
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - Constants.TAB_BUTTON_HEIGHT, width: self.view.bounds.width, height: Constants.TAB_BUTTON_HEIGHT)
        tabBarView.inputDiaryButton.setBackgroundImage(UIImage(named: "tab_image1_on"), for: .normal)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを非表示にする
        if(kibunTextBox.isFirstResponder) {
            kibunTextBox.resignFirstResponder()
        }
    }
    
    // 気分送信完了ラベル
    @IBOutlet weak var sendKibunCompleteLabel: UILabel!
    
    // サーバDBをアップデートする処理
    func updateData() {
        // ユーザーを取得
        Auth.auth().currentUser?.reload()
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        guard let userName = Auth.auth().currentUser?.displayName else {
            return
        }
        if (kibunStatus == nil) {
            return
        }

        // ドキュメントIDを事前に設定する
        let documentId = defaultStore.collection("kibuns").document().documentID
        
        var imageUrl: String = ""
        // 添付画像があるか判定
        if (isExistImage) {
            //保存したい画像のデータを変数として持つ
            var diaryImage: Data = Data()
            diaryImage = (sendImage.image?.jpegData(compressionQuality: 0.01))!
            let imageRef = storage.child("diary").child("\(documentId).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            //storageに画像を送信
            imageRef.putData(diaryImage, metadata: metadata) { (metaData, error) in
                //エラーであれば
                if error != nil {
                    print(error.debugDescription)
                    return
                }
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print(error)
                    } else {
                        imageUrl = url?.absoluteString ?? ""
                        self.updateDiary(userId: userId, userName: userName, documentId: documentId, imageUrl: imageUrl)
                    }
                }
            }
        } else {
            updateDiary(userId: userId, userName: userName, documentId: documentId)
        }
    }
    
    // 日記をアップロードする処理
    func updateDiary(userId: String, userName: String, documentId: String, imageUrl: String = "") {
        defaultStore.collection("kibuns").document(documentId).setData([
            "kibun": kibunStatus!,
            "date": Functions.today(),
            "text": kibunTextBox.text ?? "",
            "name": userName,
            "user_id": userId,
            "time": Date(),
            "documentId": documentId,
            "image": imageUrl
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.sendKibunCompleteLabel.isHidden = true
            } else {
                self.sendKibunCompleteLabel.text = "今日の気分を送信しました！"
                self.sendKibunCompleteLabel.isHidden = false
                self.sendImage.image = UIImage(named: "diary_image_icon")
            }
            self.dismissIndicator()
            self.kibunTextBox.text = ""
            self.sendButton.isEnabled = false
            self.sendButton.backgroundColor = UIColor(red: 225/255, green: 205/255, blue: 203/255, alpha: 1)
            self.remainingTextCountLabel.text = "300"
        }
    }
}

extension InputKibunViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView){
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        } else {
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor(red: 225/255, green: 205/255, blue: 203/255, alpha: 1)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            sendButton.isEnabled = true
            sendButton.backgroundColor = UIColor(red: 112/255, green: 67/255, blue: 74/255, alpha: 1)
        } else {
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor(red: 225/255, green: 205/255, blue: 203/255, alpha: 1)
        }
        // 入力を反映させたテキストを取得する
        let resultText: String = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        self.remainingTextCountLabel.text = String(300 - resultText.count)
        if resultText.count < 300 {
            return true
        }
        return false
    }
}

extension InputKibunViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickerImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }

        //CropViewControllerを初期化する。pickerImageを指定する。
        let cropController = CropViewController(croppingStyle: .default, image: pickerImage)

        cropController.delegate = self

        //AspectRatioのサイズをimageViewのサイズに合わせる。
        cropController.customAspectRatio = sendImage.frame.size

        //今回は使わない、余計なボタン等を非表示にする。
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true

        //cropBoxのサイズを固定する。
        cropController.cropView.cropBoxResizeEnabled = false

        //pickerを閉じたら、cropControllerを表示する。
        picker.dismiss(animated: true) {

            self.present(cropController, animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension InputKibunViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        //トリミング編集が終えたら、呼び出される。
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }

    func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        //トリミングした画像をimageViewのimageに代入する。
        self.sendImage.image = image
        self.isExistImage = true

        cropViewController.dismiss(animated: true, completion: nil)
    }
}
