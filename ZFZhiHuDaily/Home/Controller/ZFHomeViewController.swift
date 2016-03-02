//
//  ZFHomeViewController.swift
//  ZFZhiHuDaily
//
//  Created by 任子丰 on 16/1/6.
//  Copyright © 2016年 任子丰. All rights reserved.
//

import UIKit

class ZFHomeViewController: ZFBaseViewController, UITableViewDelegate, UITableViewDataSource, ParallaxHeaderViewDelegate, CyclePictureViewDelegate{
    /// 轮播图View
    var cyclePictureView: CyclePictureView!
    /// 轮播图图片url数组
    var imageURLArray : [String] = []
    /// 轮播图的标题数据
    var imageTitleArray : [String] = []
    /// 页数的下标，用来计算接口中传的Date
    var dateIndex : Int = 1

    @IBOutlet weak var tableView: UITableView!
    //ViewModel
    private var viewModel : ZFMainViewModel! = ZFMainViewModel()
    //轮播图数据源
    var headerSource : [ZFTopStories] = []
    //table数据源
    var dataSoure : [[ZFStories]] = []
    /// 存放内容id的数组
    var newsIdArray : [String]!
    //是否正在刷新
    var isLoading : Bool! = false
    //存放header（日期）的数组
    var headerTitleArray : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.whiteColor()
        setRefreshView()
        //左侧item
        createLeftNavWithImage("Home_Icon")
        //获取数据源
        viewModel.getData({(dataSoure,headerSource) -> Void in
            self.dataSoure.insert(dataSoure, atIndex: 0)
            self.headerSource = headerSource
            self.setTableHeaderData()
            self.tableView.reloadData()
            }) { (error) -> Void in 
        }
        //设置navbar颜色
        statusView.dk_backgroundColorPicker = ThemeColorWithAlpha(0)
        navView.dk_backgroundColorPicker = ThemeColorWithAlpha(0)
        
        //初始化轮播图
        cyclePictureView = CyclePictureView(frame: CGRectMake(0, 0, ScreenWidth, ScreenWidth/1.88), imageURLArray: nil)
        cyclePictureView.currentDotColor = UIColor.whiteColor()
        cyclePictureView.timeInterval = 4.0
        cyclePictureView.delegate = self
        //初始化Header
        let heardView = ParallaxHeaderView(style: .Default, subView: cyclePictureView, headerViewSize: CGSizeMake(ScreenWidth, ScreenWidth/1.88), maxOffsetY: -64, delegate:self)
        
        self.tableView.tableHeaderView = heardView
        self.tableView.dk_separatorColorPicker = TAB_SEPAROTOR
        self.tableView.dk_backgroundColorPicker = CELL_COLOR
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        LightStatusBar()
        openTheDrawerGesture()
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        LightStatusBar()
    }
    
    //轮播图数据源
    func setTableHeaderData() {
        //显示第一页布局
        self.cyclePictureView.layoutFirstPage()
        for news:ZFTopStories in self.headerSource {
            imageURLArray.append(news.image!)
            imageTitleArray.append(news.title!)
        }
        cyclePictureView.imageURLArray = imageURLArray
        cyclePictureView.imageDetailArray = imageTitleArray
        cyclePictureView.timeInterval = 3
    }
    
    func setRefreshView() {
        refreshView.attachObserveToScrollView(self.tableView, target: self, action: "updateData")
    }
    // MARK: - Action
    //打开抽屉
    override func didClickLeft() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.drawerController.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    //下拉刷新
    func updateData() {
        //获取数据源
        viewModel.getData({(dataSoure,headerSource) -> Void in
            //先清空第一个数据源
            self.dataSoure.removeFirst()
            self.headerSource.removeAll()
            self.imageURLArray.removeAll()
            self.imageTitleArray.removeAll()
            self.dataSoure.insert(dataSoure, atIndex: 0)
            self.headerSource = headerSource
            self.setTableHeaderData()
            self.refreshView.endRefreshing()
            self.tableView.reloadData()
            }) { (error) -> Void in
        }
    }
    //上拉加载
    func pullMoreData() {
        if self.isLoading == true {
            return;
        }
        self.isLoading = !self.isLoading
        viewModel.getDataForDate( dateIndex, successCallBack: { (dataSoure,dateStr) -> Void in
            self.dateIndex++
            self.isLoading = !self.isLoading
            self.dataSoure.append(dataSoure)
            self.headerTitleArray.append(dateStr)
            self.tableView.reloadData()
            self.refreshView.endRefreshing()
            }) { (error) -> Void in
                
        }
    }
    
    /********************************** Delegate Methods ***************************************/
    // MARK: - UITableView Delegate 
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.dataSoure.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let array = self.dataSoure[section]
        return array.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : ZFHomeCell = tableView.dequeueReusableCellWithIdentifier("homeCell") as! ZFHomeCell
        let array = self.dataSoure[indexPath.section]
        cell.news = array[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 44
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 {
            let headerView = UIView()
            headerView.dk_backgroundColorPicker = TAB_HEADER
            let titleLabel = UILabel()
            titleLabel.text = self.headerTitleArray[section-1]
            titleLabel.textColor = UIColor.whiteColor()
            titleLabel.textAlignment = .Center
            titleLabel.frame = CGRectMake(0, 0, ScreenWidth, 44)
            headerView.addSubview(titleLabel)
            return headerView
        }else {
            return nil
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let heardView = self.tableView.tableHeaderView as! ParallaxHeaderView
        heardView.layoutHeaderViewWhenScroll(scrollView.contentOffset)
        let offSetY = scrollView.contentOffset.y
        // 上拉加载
        if (offSetY  > scrollView.contentSize.height - 1.5 * ScreenHeight) {
            pullMoreData()
        }
        
        let dateHeaderHeight : CGFloat = 44.0;
        if (offSetY < dateHeaderHeight && offSetY >= 0) {
            
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }
        else if (offSetY >= dateHeaderHeight) {//偏移20
            
            scrollView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        }
        
        let firstArray = self.dataSoure[0]
        //第一个section到达后 隐藏navbar 和 标题
        if (offSetY >=  (CGFloat)(80.0*firstArray.count+164*2)+88) {
            navView.alpha = 0;
        }else {
            navView.alpha = 1.0;
        }
    }
    
    // MARK: - ParallaxHeaderViewDelegate
    
    func LockScorllView(maxOffsetY: CGFloat) {
        self.tableView.contentOffset.y = maxOffsetY
    }
    
    func autoAdjustNavigationBarAplha(aplha: CGFloat) {
        statusView.dk_backgroundColorPicker = ThemeColorWithAlpha(aplha)
        navView.dk_backgroundColorPicker = ThemeColorWithAlpha(aplha)
    }

     // MARK:- CirCleViewDelegate Methods
    
    func clickCurrentImage(currentIndxe: Int) {
        print(currentIndxe);
    }
    
    // MARK: - CyclePictureViewDelegate Methods
    
    func cyclePictureView(cyclePictureView: CyclePictureView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let newsDetailVC = GET_SB("Main").instantiateViewControllerWithIdentifier("ZFNewsDetailViewController") as! ZFNewsDetailViewController
        self.navigationController?.pushViewController(newsDetailVC, animated: true)
        let topic = self.headerSource[indexPath.row]
        newsDetailVC.newsId = String(topic.internalIdentifier!)
        self.newsIdArray = []
        for (var i = 0 ; i < self.dataSoure.count ; i++) {
            let array = self.dataSoure[i]
            for (var j = 0 ; j < array.count ; j++) {
                let story = array[j]
                self.newsIdArray.append((String)(story.internalIdentifier!))
            }
        }
        newsDetailVC.newsIdArray = self.newsIdArray
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let newsDetailVC  = segue.destinationViewController as! ZFNewsDetailViewController
        let cell = sender! as! UITableViewCell
        let indexPath =  self.tableView.indexPathForCell(cell)!
        //取消cell选中
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let array = self.dataSoure[indexPath.section]
        let news = array[indexPath.row]
        newsDetailVC.newsId = String(news.internalIdentifier!)
        self.newsIdArray = []
        for (var i = 0 ; i < self.dataSoure.count ; i++) {
            let array = self.dataSoure[i]
            for (var j = 0 ; j < array.count ; j++) {
                let story = array[j]
                self.newsIdArray.append((String)(story.internalIdentifier!))
            }
        }
        newsDetailVC.newsIdArray = self.newsIdArray
    }


}
