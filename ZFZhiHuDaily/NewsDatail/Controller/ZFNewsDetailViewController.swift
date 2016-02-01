//
//  ZFNewsDetailViewController.swift
//  ZFZhiHuDaily
//
//  Created by 任子丰 on 16/1/12.
//  Copyright © 2016年 任子丰. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher

class ZFNewsDetailViewController: ZFBaseViewController,UIWebViewDelegate {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var zanBtn: ZanButton!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var commentNumLabel: UILabel!
    @IBOutlet weak var zanNumLabel: UILabel!
    /// 新闻id
    var newsId : String!
    var viewModel = ZFNewsDetailViewModel()
    var backgroundImg : UIImageView!
    var heardView : ParallaxHeaderView!
    /// 新闻额外信息
    var newsExtra : ZFNewsExtra!
    /// loading
    var activityIndicatorView : NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //隐藏左侧item
        self.navigationItem.hidesBackButton = true;
        self.navigationItem.title = "";
        
        
        backgroundImg = UIImageView()
        backgroundImg.contentMode = .ScaleAspectFill
        backgroundImg.clipsToBounds = true
        backgroundImg.frame = CGRectMake(0, 0, ScreenWidth, CGFloat(IN_WINDOW_HEIGHT))
        
        self.webView.scrollView.addSubview(backgroundImg)
        
        let x = self.view.center.x
        let y = self.view.center.y
        let width = CGFloat(50.0)
        let height = CGFloat(50.0)
        
        activityIndicatorView = NVActivityIndicatorView(frame: CGRectMake(x, y, width, height), type: .BallClipRotatePulse, color: UIColor.lightGrayColor(), size: CGSizeMake(50, 50))
        activityIndicatorView.center = self.view.center
        activityIndicatorView.startAnimation()
        self.view.addSubview(activityIndicatorView)
        
        //赞
        setupZan()
        //获取新闻详情
        viewModel.loadNewsDetail(self.newsId, complate: { (newsDetail) -> Void in
            if let img = newsDetail.image {
                self.topView.alpha = 0
                self.backgroundImg.hidden = false
                LightStatusBar()
                self.backgroundImg.kf_setImageWithURL(NSURL(string: img)!, placeholderImage: UIImage(named: "avatar"))
                self.webView.scrollView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0)
            }else {
                self.backgroundImg.hidden = true
                self.topView.alpha = 1
                BlackStatusBar()
                self.webView.scrollView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0)
            }
            if  var body = newsDetail.body {
                if let css = newsDetail.css {
                    var temp = ""
                    for c in css {
                        temp = "<link href='\(c)' rel='stylesheet' type='text/css' />\(temp)"
                    }
                    //由于它的CSS中已经写死了 顶部图片的高度就是200,因此这个地方需要增加一个CSS 来根据设备的大小来改变图片的高度
                    body = "\(temp) <style> .headline .img-place-holder { height: \(IN_WINDOW_HEIGHT)px;}</style> \(body)"
                }
                
                self.webView.loadHTMLString(body, baseURL: nil)
            }

            }) { (error) -> Void in
        }
        
        /// 获取新闻额外信息
        viewModel.loadNewsExra(self.newsId, complate: { (newsExtra) -> Void in
            self.newsExtra = newsExtra
            self.commentNumLabel.text = "\(newsExtra.comments!)"
            self.zanBtn.initNumber = newsExtra.popularity!
            self.zanNumLabel.text = "\(newsExtra.popularity!)"
            }) { (error) -> Void in
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setMyBackgroundColor(RGBA(0, 130, 210, 0))
        closeTheDrawerGesture()
    }
    // MARK: - SetupUI
    
    func setupZan() {
        zanBtn.zanImage = UIImage(named: "News_Navigation_Vote")
        zanBtn.zanedImage = UIImage(named: "News_Navigation_Voted")
        //赞
        zanBtn.zanAction = { (number) -> Void in
            self.zanNumLabel.text = "\(number)"
            self.zanNumLabel.textColor = ThemeColor
            self.zanNumLabel.text = "\(number)"
        }
        //取消赞
        zanBtn.unzanAction = {(number)->Void in
            self.zanNumLabel.text = "\(number)"
            self.zanNumLabel.textColor = UIColor.lightGrayColor()
            self.zanNumLabel.text = "\(number)"
        }
    }
    // MARK: - Action
    
    @IBAction func didClickLeft(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        activityIndicatorView.stopAnimation()
    }
    
    // MARK: - ParallaxHeaderViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let commentVC = segue.destinationViewController as! ZFNewsCommentViewController
        commentVC.commentNum = String(self.newsExtra.comments!)
        commentVC.newsId = self.newsId
    }
    

}
