//
//  Constants.h
//  popoCloud
//
//  Created by xuyang on 13-2-27.
//
//

#define LOG2FILE                        1                              //是否把log信息写入文件，正式发布需设为0

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) //运行app设备是否是ipad

#define IS_IOS5 \
([[UIDevice currentDevice].systemVersion compare:@"5.1" options:NSNumericSearch] == NSOrderedAscending)

#define IS_IOS6 \
([[UIDevice currentDevice].systemVersion compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending)                                                //是否ios6及以上系统

#define IS_IOS7 \
([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)                                                //是否ios7及以上系统

#define IS_IPHONE5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define TIMEOUT_INTERVAL                30.0                           //http请求超时时间
#define TIMEOUT_INTERVAL_UPLOAD         360.0                          //上传请求超时时间
#define TABLE_CELL_HEIGHT               55                             //默认列表高度
#define SIZE_2M                         2097152                        //2m大小文件的字节数
#define THUMBNAIL_SIZE                  85                             //缩略图的尺寸大小
#define THUMBNAIL_WIDTH_IPAD            170                            //ipad图片集缩略图宽度
#define THUMBNAIL_HEIGHT_IPAD           170                            //ipad图片集缩略图高度
#define FILE_NAME_MAX_LENGTH            90                             //文件名长度的最大值，上传需要判断
#define FILE_PATH_MAX_LENGTH            256                            //文件路径长度的最大值，上传分享需要判断
#define TIMEOUT_INTERVAL_DOWNLOAD       100.0                          //http下载，box绑定和解绑请求超时时间
#define SUBNAME_LENGTH \
(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad \
? 30 : 9)                                                             //收藏成功提示信息里文件名截取的长度

#define HTTP                            @"http://"                     //http字符串前缀
#define SERVER_URL_TAIL                 @".tonidoid.com"               //某个http请求的后缀
//#define SERVER_PROXY_PART               @"/dyn/popocloud/r.php?proxyMethod="
//#define INTERFACE_GETAUTHENTICATIONINFO @"/core/getauthenticationinfo"
//#define INTERFACE_LOGIN                 @"/core/loginprofile"
//#define INTERFACE_AUTHENTICATEPROFILE   @"/core/authenticateprofile"

#define MAXDELETEFILE  100


#if 0
#define SERVER_HOST                     @"my.paopaoyun.com"             //HUB Url地址
#define MESSAGE_SERVER_HOST             @"mr.paopaoyun.com"             //MessageRelay Url地址
#define FILE_SERVER_HOST                @"my.paopaoyun.com"             //FileRelay Url地址
#define UPGRADE_SERVER_HOST             @"upgrade.paopaoyun.com"        //Check upgrade Url地址
#elif 0
#define SERVER_HOST                     @"140.206.137.2:7151"           //HUB Url地址
#define MESSAGE_SERVER_HOST             @"140.206.137.2:7159"           //MessageRelay Url地址
#define FILE_SERVER_HOST                @"140.206.137.2:7151"           //FileRelay Url地址
#define UPGRADE_SERVER_HOST             @"test.paopaoyun.com:9005"      //Check upgrade Url地址
#elif 0
#define SERVER_HOST                     @"hub-test.paopaoyun.com"
#define MESSAGE_SERVER_HOST             @"hub-test.paopaoyun.com/msgrelay"
#define FILE_SERVER_HOST                @"hub-test.paopaoyun.com"
#define UPGRADE_SERVER_HOST             @"hub-test.paopaoyun.com:9005"
#else
#define SERVER_HOST                     @"test.paopaoyun.com"           //HUB Url地址
#define MESSAGE_SERVER_HOST             @"test-msgrelay.paopaoyun.com"  //MessageRelay Url地址
#define FILE_SERVER_HOST                @"test-filerelay.paopaoyun.com" //FileRelay Url地址
#define UPGRADE_SERVER_HOST             @"test.paopaoyun.com:9005"      //Check upgrade Url地址
#endif

#define EVENT_UPLOAD_FILE_NUM           @"uploadFileNum"               //选择图片上传文件数改变的事件名
#define GET_FILE_SERVER_INFO            @"getFileServerInfo"
#define DeleteLocalFile                 @"DeleteLocalFile"
typedef enum
{
    ///没有下载（未收藏）
    kStatusNoDownload,
    ///正在下载
    kStatusDownloading,
    ///排队等待下载
    kStatusDownloadPause,
    ///暂停下载
    kStatusDownloadStop,
    ///已经下载完（被收藏了）
    kStatusDownloaded,
    ///正在上传
    kStatusUploading = 5,
    ///等待上传
    kStatusWaitUploading,
    ///暂停上传
    kStatusPauseUploading
} DownloadStatus;

typedef enum
{
    ///没有需要自动上传的相片
    noUpload,
    ///等待自动上传状态
    waitForUpload,
    ///正在自动上传状态
    beingUpload
} UploadStatus;

typedef enum
{
    ///正在上传
    uploadingStatus,
    ///等待上传
    waitUploadStatus,
    ///暂停上传
    pauseUploadStatus
} SelectUploadStatus;

#define MAX_IMAGEPIX_X   ([[UIScreen mainScreen] scale]*2*([UIScreen mainScreen].bounds.size.width)  )          // max pix 宽度
#define MAX_IMAGEPIX_Y   ([[UIScreen mainScreen] scale]*2*([UIScreen mainScreen].bounds.size.height)  )        // max pix  高度

#define K_MAX_IMAGE_SIZE        (1024 * 1024 * 20)   //缓存阀值
#define K_MAX_IMAGE_POINTS   (30000000)   //缓存阀值

/*
 用于filefolder和picturefloder里面重新设置center
 */
#define ImageTag 11000
#define LabelTitleTag 11001
#define LabelDesTag 11002
#define LabelDesDetailTag 11003

#define MAX_FEED_BACK_LEN  1000
#define MAX_ANSWER_LEN  20

#define SHEETVIEWTAG 777

#define NoSuitableProgramAlertTag 555

#define NoNetAlertTag                       666
#define ErrorPWAlertTag                     667

//#define KX_MENU_DISMISS               @"kxmenu_dismiss"