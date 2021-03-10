import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation
import CropViewController
import FirebaseUI
import NCMB

class InputKibunViewController: UIViewController {
    // 日付文字列
    var diarySendDateString: String = Functions.today()
    // 日記送信時間変数（Kibuns.timeに入れる値）
    var diarySendDateTime: Date = Date()
    // 日記詳細の編集ボタンからの遷移か否か
    var isEditDiary: Bool = false
    // 日記ID
    var documentId: String = ""
    // 添付画像URL
    var imageUrl: String = ""
    // ユーザーID
    var userId: String = ""
    // ユーザー名
    var userName: String = ""
    // 日記本文
    var diaryText: String = ""
    // 気分ID
    var kibunId: Int? = nil
    // タイムスタンプ
    var time: Timestamp? = nil
    
    //ストレージサーバのURLを取得
    let storage = Functions.getStorageURL()
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
    // 戻るボタン
    @IBOutlet weak var backButton: UIButton!
    @IBAction func backButton(_ sender: Any) {
        let kibunDetailViewController = UIStoryboard(name: "KibunDetailViewController", bundle: nil).instantiateViewController(withIdentifier: "KibunDetailViewController") as! KibunDetailViewController
        kibunDetailViewController.diaryId = documentId
        kibunDetailViewController.userId = userId
        kibunDetailViewController.time = time
        kibunDetailViewController.userName = userName
        kibunDetailViewController.text = diaryText
        kibunDetailViewController.kibun = kibunId
        kibunDetailViewController.date = diarySendDateTime
        kibunDetailViewController.imageUrl = imageUrl
        kibunDetailViewController.modalPresentationStyle = .fullScreen
        Functions.presentAnimation(view: view)
        self.present(kibunDetailViewController, animated: false, completion: nil)
    }
    
    // DatePickerを含むView
    @IBOutlet weak var datePickerView: UIView!
    // DatePicker
    @IBOutlet weak var datePicker: UIDatePicker!
    // 日記を書く日付
    @IBOutlet weak var diaryDate: UILabel!
    // 日付を選ぶボタンタップ
    @IBAction func selectDate(_ sender: Any) {
        if (datePickerView.isHidden) {
            datePickerView.isHidden = false
        } else {
            datePickerView.isHidden = true
        }
    }

    // 日付決定ボタンタップ
    @IBAction func updateDate(_ sender: Any) {
        let formatter = DateFormatter()
        let formatter2 = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter2.dateFormat = "YYYY年MM月dd日"
        if (formatter.string(from: datePicker.date) == formatter.string(from: Date())) {
            diaryDate.text = "今日の日記"
            diarySendDateString = Functions.today()
        } else {
            diaryDate.text = "\(formatter.string(from: datePicker.date))の日記"
            diarySendDateString = formatter2.string(from: datePicker.date)
        }
        diarySendDateTime = datePicker.date
        datePickerView.isHidden = true
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
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        }
    }
    // 良いボタンタップ
    @IBOutlet weak var kibunButton1: UIButton!
    @IBAction func kibunButton1(_ sender: Any) {
        kibunStatus = 1
        if (kibunTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        }
    }
    // 普通ボタンタップ
    @IBOutlet weak var kibunButton2: UIButton!
    @IBAction func kibunButton2(_ sender: Any) {
        kibunStatus = 2
        if (kibunTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        }
    }
    // 悪いボタンタップ
    @IBOutlet weak var kibunButton3: UIButton!
    @IBAction func kibunButton3(_ sender: Any) {
        kibunStatus = 3
        if (kibunTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        }
    }
    // 最悪ボタンタップ
    @IBOutlet weak var kibunButton4: UIButton!
    @IBAction func kibunButton4(_ sender: Any) {
        kibunStatus = 4
        if (kibunTextBox.text?.count != 0) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
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
        
        if (!(UserDefaults.standard.nowInputDiaryText?.isEmpty ?? false)) {
            kibunTextBox.text = UserDefaults.standard.nowInputDiaryText
        }
        
        // 気分ボタンの画像のアス比を揃える
        kibunButton0.imageView?.contentMode = .scaleAspectFit
        kibunButton1.imageView?.contentMode = .scaleAspectFit
        kibunButton2.imageView?.contentMode = .scaleAspectFit
        kibunButton3.imageView?.contentMode = .scaleAspectFit
        kibunButton4.imageView?.contentMode = .scaleAspectFit
        
        // 編集ボタンから来た時の為の初期化処理
        if (isEditDiary) {
            kibunTextBox.text = diaryText
            kibunStatus = kibunId
            Functions.updateButtonEnabled(button: self.sendButton, enabled: true)
            
            if (imageUrl != "") {
                sendImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
                sendImage.sd_setImage(with: URL(string: imageUrl))
                isExistImage = true
            }
            if (diarySendDateString != Functions.today()) {
                diaryDate.text = diarySendDateString.dropFirst(5) + "の日記"
            }
            pushSwitchLabel.isHidden = true
            pushSwitch.isHidden = true
            
            datePicker.date = diarySendDateTime
            
            backButton.isHidden = false
        }
        
        if (UserDefaults.standard.billingProMode ?? false) {    // 課金ユーザー
            remainingTextCountLabel.isHidden = true
        } else {
            self.remainingTextCountLabel.text = String(300 - kibunTextBox.text.count)
        }
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
        tabBarView.tab.frame = CGRect(x: 0, y: self.view.frame.maxY  - (self.view.bounds.width * 0.28), width: self.view.bounds.width, height: (self.view.bounds.width * 0.28))
        // 日記編集の場合は強調するタブボタンを「いちらん」にする
        if (isEditDiary) {
            tabBarView.diaryButton.setBackgroundImage(UIImage(named: "tab_image0_on"), for: .normal)
        } else {
            tabBarView.inputDiaryButton.setBackgroundImage(UIImage(named: "tab_image1_on"), for: .normal)
        }
        
        pushSwitch.onTintColor = UIColor(red: 129/255, green: 75/255, blue: 84/255, alpha: 1)
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
        if (userId == "") {
            userId = Auth.auth().currentUser?.uid ?? "0"
        }
        if (userName == "") {
            userName = Auth.auth().currentUser?.displayName ?? "名無しの猫ちゃん"
        }
        if (kibunStatus == nil) {
            return
        }

        // ドキュメントIDを事前に設定する
        if (documentId == "") {
            documentId = defaultStore.collection("kibuns").document().documentID
        }
        
        // 添付画像があるか判定
        if (isExistImage) {
            //保存したい画像のデータを変数として持つ
            var diaryImage: Data = Data()
            var imageQuality: CGFloat = 0
            if (UserDefaults.standard.billingProMode ?? false) { // 課金ユーザー
                imageQuality = 1.0
            }
            diaryImage = (sendImage.image?.jpegData(compressionQuality: imageQuality))!
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
                        self.imageUrl = url?.absoluteString ?? ""
                        self.updateDiary(userId: self.userId, userName: self.userName, documentId: self.documentId, imageUrl: self.imageUrl)
                    }
                }
            }
        } else {
            updateDiary(userId: userId, userName: userName, documentId: documentId)
        }
    }
    
    // PUSH通知送信スイッチラベル
    @IBOutlet weak var pushSwitchLabel: UILabel!
    // PUSH通知送信スイッチ
    @IBOutlet weak var pushSwitch: UISwitch!
    
    // 日記をアップロードする処理
    func updateDiary(userId: String, userName: String, documentId: String, imageUrl: String = "") {
        defaultStore.collection("kibuns").document(documentId).setData([
            "kibun": kibunStatus!,
            "date": diarySendDateString,
            "text": kibunTextBox.text ?? "",
            "name": userName,
            "user_id": userId,
            "time": diarySendDateTime,
            "documentId": documentId,
            "image": imageUrl
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                self.sendKibunCompleteLabel.isHidden = true
            } else {
                if (self.isEditDiary) {
                    self.sendKibunCompleteLabel.text = "日記を編集しました！"
                    self.diaryText = self.kibunTextBox.text
                    self.kibunId = self.kibunStatus
                    self.time = Timestamp(date: self.diarySendDateTime)
                } else {
                    self.sendKibunCompleteLabel.text = "今日の気分を送信しました！"
                    self.kibunTextBox.text = ""
                    self.sendImage.image = UIImage(named: "diary_image_icon")
                }
                self.sendKibunCompleteLabel.isHidden = false
                
                // 家族に日記の更新をPUSH通知で送信
                if (self.pushSwitch.isOn && self.pushSwitch.isHidden == false) {
                    self.sendUpdateDiaryPush(userName: userName, myUserId: userId)
                }   
                    
                // UserDefaultsに保存してる下記途中の文章を削除
                UserDefaults.standard.nowInputDiaryText = ""
            }
            self.dismissIndicator()
            Functions.updateButtonEnabled(button: self.sendButton, enabled: false)
            self.remainingTextCountLabel.text = "300"
        }
    }
    
    // 家族にのみ日記更新通知のPUSHを送る処理
    private func sendUpdateDiaryPush(userName: String, myUserId: String) {
        // 自分が所属する家族が存在すればPUSH送信
        defaultStore.collection("families").whereField("user_id", arrayContainsAny: [myUserId]).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if (querySnapshot?.documents.count == 0) {
                    return
                }
                guard let familyDocumentId = querySnapshot?.documents[0].documentID else {
                    return
                }
                // プッシュ通知オブジェクトの作成
                let push : NCMBPush = NCMBPush()
                push.sound = "default"
                push.badgeIncrementFlag = false
                push.badgeSetting = 1
                push.contentAvailable = false
                push.searchCondition?.where(field: "channels", toMatchPattern: familyDocumentId)
                if (UserDefaults.standard.devicetokenKey != nil) {
                    let deviceTokenString = UserDefaults.standard.devicetokenKey!.map { String(format: "%.2hhx", $0) }.joined()
                    push.searchCondition?.where(field: "deviceToken", notEqualTo: deviceTokenString)
                }
                // メッセージの設定
                push.message = "\(userName)が日記を書きました"
                // 即時配信を設定する
                push.setImmediateDelivery()

                // プッシュ通知を配信登録する
                push.sendInBackground(callback: { result in
                    switch result {
                    case .success:
                        print("登録に成功しました。プッシュID: \(push.objectId!)")
                    case let .failure(error):
                        print("登録に失敗しました: \(error)")
                        return;
                    }
                })
            }
        }
    }
}

// 日記本文の編集監視
extension InputKibunViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView){
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: sendButton, enabled: false)
        }
        
        // 書き途中の日記をUserDefaultsに保存
        if (kibunTextBox.text?.count != 0 && !isEditDiary) {
            UserDefaults.standard.nowInputDiaryText = kibunTextBox.text
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (kibunTextBox.text?.count != 0 && kibunStatus != nil) {
            Functions.updateButtonEnabled(button: sendButton, enabled: true)
        } else {
            Functions.updateButtonEnabled(button: sendButton, enabled: false)
        }
        // 入力を反映させたテキストを取得する
        let resultText: String = (textView.text! as NSString).replacingCharacters(in: range, with: text)
        
        if (UserDefaults.standard.billingProMode ?? false) {    // 無課金ユーザー
            return true
        } else {
            self.remainingTextCountLabel.text = String(300 - resultText.count)
            if resultText.count < 300 {
                return true
            }
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
