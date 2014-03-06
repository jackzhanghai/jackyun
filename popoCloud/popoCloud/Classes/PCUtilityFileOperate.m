//
//  PCUtilityFileOperate.m
//  popoCloud
//
//  Created by xy  on 13-8-26.
//
//

#import "PCUtilityFileOperate.h"
#import "PCUtilityDataManagement.h"
#import "PCLogin.h"
#include <libkern/OSAtomic.h>

@implementation PCUtilityFileOperate

static NSDictionary* gFileTypeImage = nil;
static FileDownloadManager* gDownloadManger = nil;

+ (BOOL)livingMediaSupport:(NSString *)ext
{
    NSString *upCase = [ext lowercaseString];
    if (ext == nil) {
        return NO;
    }
    else if  ([upCase isEqualToString: @"mov"]
              ||[upCase isEqualToString: @"mp4"]
              ||[upCase isEqualToString: @"mp3"]
              ||[upCase isEqualToString: @"wav"]
              ||[upCase isEqualToString: @"aiff"]
              )
    {
        return  YES;
    }
    
    return NO;
}

/**
 用QLPreviewControler和后缀名结合判断是否能够打开指定路径的文件
 add by libing 2013-6-26  for fix bugID55854，58438
 */

+ (BOOL)itemCanOpenWithPath:(NSString *)path
{
    if (!path)
    {
        return NO;
    }
    
    NSString *extension = [[path pathExtension] lowercaseString];
    NSString *type = [PCUtilityFileOperate getImgByExt:extension];
    if ([type isEqualToString:@"file_video.png"] ||
        [type isEqualToString:@"file_music.png"])
    {
        //本地有文件
//        if([[NSFileManager defaultManager] fileExistsAtPath:path])
//        {
//            if ([extension isEqualToString:@"amr"])
//            {
//                return NO;
//            }
//            else
//            {
//                AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
//                return asset.playable;
//            }
//        }
//        else
        {
            //取得后缀名
            if ([extension isEqualToString:@"mp4"] ||
                [extension isEqualToString:@"mov"] ||
                [extension isEqualToString:@"m4v"] ||
                [extension isEqualToString:@"avi"] ||
                [extension isEqualToString:@"3gp"] ||
                [extension isEqualToString:@"mp3"] ||
                [extension isEqualToString:@"wav"] ||
                [extension isEqualToString:@"aac"] ||
                [extension isEqualToString:@"aax"] ||
                [extension isEqualToString:@"m4a"] ||
                [extension isEqualToString:@"m4r"] ||
                [extension isEqualToString:@"aiff"])
            {
                return YES;
            }
            else
            {
                return NO;
            }
        }
        
    }
    
    BOOL canPlay = [QLPreviewController canPreviewItem:(id<QLPreviewItem>)[NSURL fileURLWithPath:path]];
    return canPlay;
}

+ (NSString*) getImgName:(NSString*)imgName
{
    NSMutableString *getImgName = [[[NSMutableString alloc] initWithString:imgName] autorelease];
    if (IS_IPAD) {
        [getImgName appendString:@"@2x.png"];
    }
    else {
        [getImgName appendString:@".png"];
    }
    return getImgName;
}

+ (NSString*) getXibName:(NSString*)xibName
{
    NSMutableString *getXibName = [[[NSMutableString alloc] initWithString:xibName] autorelease];
    if (IS_IPAD) {
        [getXibName appendString:@"_iPad"];
    }
    else {
        [getXibName appendString:@"_iPhone"];
    }
    return getXibName;
}

+ (NSString*) getImgByExt:(NSString*)ext 
{
    if (!gFileTypeImage) {
        gFileTypeImage = [[NSDictionary alloc] initWithObjectsAndKeys:
                          @"file_access.png", @"mdb",
                          
                          @"file_dw.png", @"swf",
                          
                          @"file_excel.png", @"xla",
                          @"file_excel.png", @"xlb",
                          @"file_excel.png", @"xlc",
                          @"file_excel.png", @"xld",
                          @"file_excel.png", @"xlk",
                          @"file_excel.png", @"xll",
                          @"file_excel.png", @"xlm",
                          @"file_excel.png", @"xls",
                          @"file_excel.png", @"xlshtml",
                          @"file_excel.png", @"xlsmhtml",
                          @"file_excel.png", @"xlt",
                          @"file_excel.png", @"xlthtml",
                          @"file_excel.png", @"xlv",
                          @"file_excel.png", @"xlsx",
                          
                          @"file_flash.png", @"fla",
                          
                          @"file_html.png", @"html",
                          @"file_html.png", @"htm",
                          
                          @"file_ai.png", @"ai",
                          
                          @"file_id.png", @"indd",
                          @"file_id.png", @"rpin",
                          @"file_id.png", @"apin",
                          
                          //                          @"file_pic.png", @"ag4",
                          //                          @"file_pic.png", @"att",
                          @"file_pic.png", @"bmp",
                          //                          @"file_pic.png", @"cal",
                          //                          @"file_pic.png", @"cit",
                          //                          @"file_pic.png", @"clp",
                          //                          @"file_pic.png", @"cmp",
                          //                          @"file_pic.png", @"cpr",
                          //                          @"file_pic.png", @"ct",
                          //                          @"file_pic.png", @"cut",
                          //                          @"file_pic.png", @"dbx",
                          //                          @"file_pic.png", @"dx",
                          //                          @"file_pic.png", @"ed6",
                          //                          @"file_pic.png", @"eps",
                          //                          @"file_pic.png", @"fax",
                          //                          @"file_pic.png", @"fmv",
                          //                          @"file_pic.png", @"ged",
                          //                          @"file_pic.png", @"gdf",
                          @"file_pic.png", @"gif",
                          //                          @"file_pic.png", @"gp4",
                          //                          @"file_pic.png", @"gx1",
                          //                          @"file_pic.png", @"gx2",
                          //                          @"file_pic.png", @"ica",
                          //                          @"file_pic.png", @"ico",
                          //                          @"file_pic.png", @"iff",
                          //                          @"file_pic.png", @"igf",
                          //                          @"file_pic.png", @"img",
                          //                          @"file_pic.png", @"jff",
                          @"file_pic.png", @"jpg",
                          @"file_pic.png", @"jpeg",
                          //                          @"file_pic.png", @"kfx",
                          //                          @"file_pic.png", @"mac",
                          //                          @"file_pic.png", @"mil",
                          //                          @"file_pic.png", @"msp",
                          //                          @"file_pic.png", @"nif",
                          //                          @"file_pic.png", @"pbm",
                          //                          @"file_pic.png", @"pcd",
                          //                          @"file_pic.png", @"pcx",
                          //                          @"file_pic.png", @"pix",
                          @"file_pic.png", @"png",
                          //                          //@"file_pic.png", @"psd",
                          //                          @"file_pic.png", @"ras",
                          //                          @"file_pic.png", @"rgb",
                          //                          @"file_pic.png", @"ria",
                          //                          @"file_pic.png", @"rlc",
                          //                          @"file_pic.png", @"rle",
                          //                          @"file_pic.png", @"rnl",
                          //                          @"file_pic.png", @"sbp",
                          //                          @"file_pic.png", @"sgi",
                          //                          @"file_pic.png", @"sun",
                          //                          @"file_pic.png", @"tga",
                          //                          @"file_pic.png", @"tif",
                          //                          @"file_pic.png", @"wpg",
                          //                          @"file_pic.png", @"xbm",
                          //                          @"file_pic.png", @"xpm",
                          //                          @"file_pic.png", @"xwd",
                          //                          @"file_pic.png", @"3ds",
                          //                          @"file_pic.png", @"906",
                          //                          @"file_pic.png", @"cal",
                          //                          @"file_pic.png", @"cdr",
                          //                          @"file_pic.png", @"cgm",
                          //                          @"file_pic.png", @"ch3",
                          //                          @"file_pic.png", @"clp",
                          //                          @"file_pic.png", @"cmx",
                          //                          @"file_pic.png", @"dg",
                          //                          @"file_pic.png", @"dgn",
                          //                          @"file_pic.png", @"drw",
                          //                          @"file_pic.png", @"ds4",
                          //                          @"file_pic.png", @"dsf",
                          //                          @"file_pic.png", @"dxf",
                          //                          @"file_pic.png", @"dwg",
                          //                          @"file_pic.png", @"emf",
                          //                          @"file_pic.png", @"esi",
                          //                          @"file_pic.png", @"fmv",
                          //                          @"file_pic.png", @"gca",
                          //                          @"file_pic.png", @"gem",
                          //                          @"file_pic.png", @"g4",
                          //                          @"file_pic.png", @"igf",
                          //                          @"file_pic.png", @"igs",
                          //                          @"file_pic.png", @"mcs",
                          //                          @"file_pic.png", @"met",
                          //                          @"file_pic.png", @"mrk",
                          //                          @"file_pic.png", @"p10",
                          //                          @"file_pic.png", @"pcl",
                          //                          @"file_pic.png", @"pdw",
                          //                          @"file_pic.png", @"pgl",
                          //                          @"file_pic.png", @"pic",
                          //                          @"file_pic.png", @"pix",
                          //                          @"file_pic.png", @"plt",
                          //                          @"file_pic.png", @"ps",
                          //                          @"file_pic.png", @"rlc",
                          //                          @"file_pic.png", @"ssk",
                          //                          @"file_pic.png", @"wmf",
                          //                          @"file_pic.png", @"wpg",
                          //                          @"file_pic.png", @"wrl",
                          //                          @"file_pic.png", @"wbmp",
                          @"file_pic.png", @"jpeg",
                          //                          @"file_pic.png", @"tiff",
                          
                          @"file_music.png", @"aac",
                          @"file_music.png", @"ac3",
                          @"file_music.png", @"amr",
                          
                          @"file_music.png", @"a2b",
                          @"file_music.png", @"ac1d",
                          @"file_music.png", @"ac-3",
                          @"file_music.png", @"aif",
                          @"file_music.png", @"aiff",
                          @"file_music.png", @"ais",
                          @"file_music.png", @"alaw",
                          @"file_music.png", @"alm",
                          @"file_music.png", @"am",
                          @"file_music.png", @"amd",
                          @"file_music.png", @"amm",
                          @"file_music.png", @"ams",
                          @"file_music.png", @"apex",
                          @"file_music.png", @"ase",
                          @"file_music.png", @"asx",
                          @"file_music.png", @"au",
                          @"file_music.png", @"aud",
                          @"file_music.png", @"avr",
                          @"file_music.png", @"bik",
                          @"file_music.png", @"bnk",
                          @"file_music.png", @"bpm",
                          @"file_music.png", @"c01",
                          @"file_music.png", @"cda",
                          @"file_music.png", @"cdr",
                          @"file_music.png", @"cmf",
                          @"file_music.png", @"d00",
                          @"file_music.png", @"dcm",
                          @"file_music.png", @"dewf",
                          @"file_music.png", @"di",
                          @"file_music.png", @"dig",
                          @"file_music.png", @"dls",
                          @"file_music.png", @"dmf",
                          @"file_music.png", @"dsf",
                          @"file_music.png", @"dsm",
                          @"file_music.png", @"dtm",
                          @"file_music.png", @"dwd",
                          @"file_music.png", @"eda",
                          @"file_music.png", @"ede",
                          @"file_music.png", @"edk",
                          @"file_music.png", @"edq",
                          @"file_music.png", @"eds",
                          @"file_music.png", @"edv",
                          @"file_music.png", @"efa",
                          @"file_music.png", @"efe",
                          @"file_music.png", @"efk",
                          @"file_music.png", @"efq",
                          @"file_music.png", @"efs",
                          @"file_music.png", @"efv",
                          @"file_music.png", @"emb",
                          @"file_music.png", @"emd",
                          @"file_music.png", @"emu",
                          @"file_music.png", @"esps",
                          @"file_music.png", @"eui",
                          @"file_music.png", @"eureka",
                          @"file_music.png", @"f2r",
                          @"file_music.png", @"f32",
                          @"file_music.png", @"f3r",
                          @"file_music.png", @"f64",
                          @"file_music.png", @"far",
                          @"file_music.png", @"fc-m",
                          @"file_music.png", @"fff",
                          @"file_music.png", @"fnk",
                          @"file_music.png", @"fpt",
                          @"file_music.png", @"fsm",
                          @"file_music.png", @"fzb",
                          @"file_music.png", @"fzf",
                          @"file_music.png", @"fzv",
                          @"file_music.png", @"g721",
                          @"file_music.png", @"g723",
                          @"file_music.png", @"g726",
                          @"file_music.png", @"gdm",
                          @"file_music.png", @"gig",
                          @"file_music.png", @"gkh",
                          @"file_music.png", @"gmc",
                          @"file_music.png", @"gsm",
                          @"file_music.png", @"gts",
                          @"file_music.png", @"hcom",
                          @"file_music.png", @"hrt",
                          @"file_music.png", @"idf",
                          @"file_music.png", @"iff",
                          @"file_music.png", @"ini",
                          @"file_music.png", @"inrs",
                          @"file_music.png", @"ins",
                          @"file_music.png", @"ist",
                          @"file_music.png", @"it",
                          @"file_music.png", @"its",
                          @"file_music.png", @"k25",
                          @"file_music.png", @"kar",
                          @"file_music.png", @"kmp",
                          @"file_music.png", @"kr1",
                          @"file_music.png", @"kris",
                          @"file_music.png", @"krZ",
                          @"file_music.png", @"ksc",
                          @"file_music.png", @"ksf",
                          @"file_music.png", @"ksm",
                          @"file_music.png", @"liq",
                          @"file_music.png", @"lqt",
                          @"file_music.png", @"lsf",
                          @"file_music.png", @"lsx",
                          @"file_music.png", @"m3u",
                          @"file_music.png", @"mat",
                          @"file_music.png", @"maud",
                          @"file_music.png", @"mav",
                          @"file_music.png", @"mdlmed",
                          @"file_music.png", @"mid",
                          @"file_music.png", @"midi",
                          @"file_music.png", @"miv",
                          @"file_music.png", @"mls",
                          @"file_music.png", @"mms",
                          @"file_music.png", @"mod",
                          @"file_music.png", @"mp",
                          @"file_music.png", @"mp1",
                          @"file_music.png", @"mp2",
                          @"file_music.png", @"mpa",
                          @"file_music.png", @"mp3",
                          @"file_music.png", @"mtm",
                          @"file_music.png", @"mtr",
                          @"file_music.png", @"mus",
                          @"file_music.png", @"mus10",
                          @"file_music.png", @"niff",
                          @"file_music.png", @"nist",
                          @"file_music.png", @"np?",
                          @"file_music.png", @"o01",
                          @"file_music.png", @"pac",
                          @"file_music.png", @"pat",
                          @"file_music.png", @"pbf",
                          @"file_music.png", @"pcm",
                          @"file_music.png", @"player",
                          @"file_music.png", @"plm",
                          @"file_music.png", @"pls",
                          @"file_music.png", @"pm",
                          @"file_music.png", @"prg",
                          @"file_music.png", @"ps16",
                          @"file_music.png", @"psb",
                          @"file_music.png", @"psion",
                          @"file_music.png", @"psm",
                          @"file_music.png", @"ptm",
                          @"file_music.png", @"ra",
                          @"file_music.png", @"rad",
                          @"file_music.png", @"raw",
                          @"file_music.png", @"rcp",
                          @"file_music.png", @"rmf",
                          @"file_music.png", @"rmi",
                          @"file_music.png", @"rol",
                          @"file_music.png", @"rtm",
                          @"file_music.png", @"s3i",
                          @"file_music.png", @"s3m",
                          @"file_music.png", @"sam",
                          @"file_music.png", @"sb",
                          @"file_music.png", @"sbk",
                          @"file_music.png", @"sc2",
                          @"file_music.png", @"sd",
                          @"file_music.png", @"sd2",
                          @"file_music.png", @"sdk",
                          @"file_music.png", @"sds",
                          @"file_music.png", @"sdw",
                          @"file_music.png", @"sdx",
                          @"file_music.png", @"sf2",
                          @"file_music.png", @"sfd",
                          @"file_music.png", @"sfi",
                          @"file_music.png", @"sfm",
                          @"file_music.png", @"sfr",
                          @"file_music.png", @"skyt",
                          @"file_music.png", @"smp",
                          @"file_music.png", @"snd",
                          @"file_music.png", @"sndr",
                          @"file_music.png", @"sndt",
                          @"file_music.png", @"sou",
                          @"file_music.png", @"spd",
                          @"file_music.png", @"spl",
                          @"file_music.png", @"spp",
                          @"file_music.png", @"sss",
                          @"file_music.png", @"stm",
                          @"file_music.png", @"svx",
                          @"file_music.png", @"sw",
                          @"file_music.png", @"syw",
                          @"file_music.png", @"tex",
                          @"file_music.png", @"tjs",
                          @"file_music.png", @"tp?",
                          @"file_music.png", @"txw",
                          @"file_music.png", @"ub",
                          @"file_music.png", @"udw",
                          @"file_music.png", @"ulaw",
                          @"file_music.png", @"ult",
                          @"file_music.png", @"uni",
                          @"file_music.png", @"unic",
                          @"file_music.png", @"uw",
                          @"file_music.png", @"uwf",
                          @"file_music.png", @"v8",
                          @"file_music.png", @"vap",
                          @"file_music.png", @"voc",
                          @"file_music.png", @"vox",
                          @"file_music.png", @"vqf",
                          @"file_music.png", @"wav",
                          @"file_music.png", @"wfb",
                          @"file_music.png", @"wfd",
                          @"file_music.png", @"wfp",
                          @"file_music.png", @"wma",
                          @"file_music.png", @"wn",
                          @"file_music.png", @"wow",
                          @"file_music.png", @"xann",
                          @"file_music.png", @"xi",
                          @"file_music.png", @"xm",
                          @"file_music.png", @"xmi",
                          @"file_music.png", @"xms",
                          @"file_music.png", @"zen",
                          @"file_music.png", @"669",
                          @"file_music.png", @"8svx",
                          @"file_music.png", @"m4a",
                          @"file_music.png", @"awb",
                          @"file_music.png", @"ogg",
                          @"file_music.png", @"oga",
                          @"file_music.png", @"mka",
                          @"file_music.png", @"xmf",
                          @"file_music.png", @"rtttl",
                          @"file_music.png", @"smf",
                          @"file_music.png", @"imy",
                          @"file_music.png", @"rtx",
                          @"file_music.png", @"ota",
                          @"file_music.png", @"flac",
                          @"file_music.png", @"ape",
                          @"file_music.png", @"aa",
                          @"file_music.png", @"aax",
                          @"file_music.png", @"f4a",
                          @"file_music.png", @"m4r",
                          @"file_music.png", @"wv",
                          
                          @"file_pdf.png", @"pdf",
                          
                          @"file_ps.png", @"psd",
                          
                          @"file_ppt.png", @"ppt",
                          @"file_ppt.png", @"pptx",
                          @"file_ppt.png", @"pptm",
                          @"file_ppt.png", @"pot",
                          @"file_ppt.png", @"potx",
                          @"file_ppt.png", @"potm",
                          
                          @"file_rar.png", @"rar",
                          @"file_rar.png", @"7z",
                          @"file_zip.png", @"zip",
                          
                          @"file_rtf.png", @"rtf",
                          
                          @"file_txt.png", @"log",
                          @"file_txt.png", @"txt",
                          
                          @"file_video.png", @"avi",
                          @"file_video.png", @"rmvb",
                          @"file_video.png", @"rm",
                          @"file_video.png", @"asf",
                          @"file_video.png", @"divx",
                          @"file_video.png", @"mpg",
                          @"file_video.png", @"mpeg",
                          @"file_video.png", @"mpe",
                          @"file_video.png", @"wmv",
                          @"file_video.png", @"mp4",
                          @"file_video.png", @"mkv",
                          @"file_video.png", @"vob",
                          @"file_video.png", @"m4v",
                          @"file_video.png", @"mov",
                          @"file_video.png", @"mp4",
                          @"file_video.png", @"asf",
                          @"file_video.png", @"3gp",
                          @"file_video.png", @"3gpp",
                          @"file_video.png", @"3g2",
                          @"file_video.png", @"3gpp2",
                          @"file_video.png", @"webm",
                          @"file_video.png", @"ts",
                          @"file_video.png", @"qt",
                          @"file_video.png", @"flv",
                          @"file_video.png", @"f4v",
                          @"file_video.png", @"ogm",
                          @"file_video.png", @"ogv",
                          @"file_video.png", @"mts",
                          @"file_video.png", @"m2ts",
                          
                          @"file_visio.png", @"vsd",
                          
                          @"file_word.png", @"doc",
                          @"file_word.png", @"docx",
                          
                          nil];
    }
    
    if (![ext  isKindOfClass:[NSString class]]) {
        return @"file_unrecognize.png";
    }
    
    NSString* imgFile = [gFileTypeImage objectForKey:[ext lowercaseString]];
    if (!imgFile) imgFile = @"file_unrecognize.png";
    return imgFile;
}

+ (NSString*) formatFileSize:(long long)size isNeedBlank:(BOOL)isNeedBlank {
    NSString *result = nil;
    NSString *blank = @"";
    if (isNeedBlank) blank = @" ";
    if (size >= 1073741824) {
        result = [NSString stringWithFormat:@"%.2f%@GB",  (double)size / 1073741824, blank];
    }
    else if (size >= 1048576) {
        result = [NSString stringWithFormat:@"%.2f%@MB",  (double)size / 1048576, blank];
    }
    else if (size >= 1024) {
        result = [NSString stringWithFormat:@"%.2f%@KB",  (double)size / 1024, blank];
    }
    else if (size != 1) {
        result = [NSString stringWithFormat:@"%qi%@%@", size, blank, NSLocalizedString(@"Bytes", nil)];
    }
    else {
        result = [NSString stringWithFormat:@"%qi%@%@", size, blank, NSLocalizedString(@"Byte", nil)];
    }
    
    return result;
    
}

/**
 * 获取上传图片文件的二进制数据
 * @param present ALAssetRepresentation实例
 * @return 上传文件的数据
 */
+ (NSData *)getUploadImageData:(ALAssetRepresentation *)present
{
    long long size = present.size;
    uint8_t *data = malloc(size);
    
    NSError *error = nil;
    NSUInteger result = [present getBytes:data fromOffset:0 length:size error:&error];
    
    if (result == 0)
    {
        DLogError(@"get upload image data error:%@",error.localizedDescription);
    }
    
    return result ? [NSData dataWithBytesNoCopy:data length:size] : nil;
}

/**
 * 移动缓存的文件到收藏（下载）目录
 * @param hostPath 文件在云端的目录地址
 * @param size 文件大小
 * @param fileCache FileCache实例
 * @param type 缓存文件类型
 * @return 移动成功返回YES，否则NO
 */
+ (BOOL)moveCacheFileToDownload:(NSString *)hostPath
                       fileSize:(long long)size
                      fileCache:(FileCache *)fileCache
                       fileType:(NSInteger)type
{
    NSString *downFilePath = [fileCache getCacheFilePath:hostPath withType:TYPE_DOWNLOAD_FILE];
    NSString *cacheFilePath = [fileCache getCacheFilePath:hostPath withType:type];
    //    NSString *modifyTime = [NSString stringWithFormat:@"%@",[node objectForKey:@"modifyTime"]];
    
    //更新FileCacheInfo表里对应的该缓存文件记录的path和type字段
    [fileCache updateCacheInfo:cacheFilePath newPath:downFilePath];
    
    //添加记录到FileDownloadedInfo
    if (size != 0) {
        [[PCUtilityFileOperate downloadManager] finishItem:hostPath
                                      localPath:downFilePath
                                     modifyTime:nil
                                       fileSize:size];
    }
    
    //把缓存文件移动到Download文件夹
    NSString *downFolder = [downFilePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:downFolder])
    {
        [fileManager createDirectoryAtPath:downFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:cacheFilePath toPath:downFilePath error:&error];
    if (!success)
    {
        DLogError(@"moveCacheFileToDownload move file error:%@",error.localizedDescription);
    }
    return success;
}

/**
 * 移动收藏下载的文件到缓存目录
 * @param hostPath 文件在云端的目录地址
 * @param downFilePath 收藏的文件的路径
 * @return 移动成功返回缓存文件路径，否则nil
 */

+ (NSString *)moveDownloadFileToCache:(NSString *)hostPath
                             downPath:(NSString *)downFilePath
{
    NSString *relativePath = [FileCache getRelativePath:hostPath
                                               withType:TYPE_CACHE_FILE
                                              andDevice:[PCLogin getResource]];
//    NSString *cacheFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:relativePath];
    NSString *cacheFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:relativePath];
    
    //更新FileCacheInfo表里对应的该缓存文件记录的path和type字段
    PCFileCacheInfo *fileCache = [FileCache fetchCacheFile:downFilePath];
    
    if (fileCache)
    {
        fileCache.path = cacheFilePath;
        fileCache.type = @"Cache";
        [[PCUtilityDataManagement managedObjectContext] save:nil];
    }
    
    //把文件移动到缓存文件夹
    NSString *cacheFolder = [cacheFilePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:cacheFolder])
    {
        [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *error = nil;
    BOOL success = [fileManager moveItemAtPath:downFilePath toPath:cacheFilePath error:&error];
    if (!success)
    {
        DLogError(@"moveDownloadFileToCache move file error:%@",error.localizedDescription);
        return nil;
    }
    else
    {
        [[PCUtilityFileOperate downloadManager] deleteDownloadItem:hostPath fileStatus:kStatusDownloaded];
    }
    return cacheFilePath;
}


+ (FileDownloadManager*) downloadManager
{
    if (!gDownloadManger) {
        gDownloadManger = [[FileDownloadManager alloc] init];
    }
    
    return gDownloadManger;
}


+ (BOOL) checkPrivacyForAlbum
{
    __block BOOL accessGranted = NO;
    __block int32_t counter = 0;
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (*stop) {
            return;
        }
        // access granted
        *stop = TRUE;
        accessGranted = YES;
        OSAtomicDecrement32(&counter);
    } failureBlock:^(NSError *error) {
        // User denied access
        accessGranted = NO;
        OSAtomicDecrement32(&counter);
    }];
    [assetsLibrary release];
    
    while (counter >= 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    return accessGranted;
}

/**
 * 登陆成功后检查缓存和收藏文件是否还在沙盒里存在（可能会被系统清除），若不存在则删除数据库里的记录
 */
+ (void)checkDownloadFilesExist
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
//    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Caches"];
    NSString *cacheFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/Caches"];
    NSString *downloadFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/Download"];
    NSArray *folderArr = @[cacheFolder, downloadFolder];
    
    for (int i = 0; i < folderArr.count; i++)
    {
        NSString *path = folderArr[i];
        if (![fileManager fileExistsAtPath:path])
        {
            NSString *type = i == 0 ? @"Cache" : @"Download";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type == %@)", type];
            
            NSArray *fetchArray = [PCUtilityDataManagement fetchObjects:@"FileCacheInfo"
                                          sortDescriptors:nil
                                                predicate:predicate
                                               fetchLimit:0
                                                cacheName:@"delete"];
            
            for (PCFileCacheInfo *info in fetchArray)
            {
                [[PCUtilityDataManagement managedObjectContext] deleteObject:info];
            }
            
            [[PCUtilityDataManagement managedObjectContext] save:nil];
        }
    }
}

+(void) deleteFile:(NSString*)path
{
    NSFileManager *fileManage = [NSFileManager defaultManager];
    [fileManage removeItemAtPath:path error:nil];
}

+ (void) openFileAtPath:(NSString*)path WithBackTitle:(NSString*)title andFileInfo:(PCFileInfo*)fileInfo andNavigationViewControllerDelegate:(UIViewController*)delegate
{
    //add by libing 2013-6-26 fix bug bug54838  bug 55854
    BOOL result = [PCUtilityFileOperate itemCanOpenWithPath:path];
    if (!result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Prompt", nil) message:NSLocalizedString(@"NoSuitableProgram", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else
    {
        //避免null值 无  pathextention方法导致 crash
        id curPath = fileInfo.path;
        if (![curPath isKindOfClass:[NSString class]]) {
            curPath =   @"";
        }
        QLPreviewController2 *previewController = [[QLPreviewController2 alloc] init];
        previewController.currentFileInfo = fileInfo;
        
        if ([[PCUtilityFileOperate getImgByExt:[curPath pathExtension]] isEqualToString:@"file_video.png"] ||
            [[PCUtilityFileOperate getImgByExt:[curPath pathExtension]] isEqualToString:@"file_music.png"])
        {
            previewController.bHideToolbarForMusicFile = YES;
        }
        
        previewController.localPath = path;
        previewController.dataSource = previewController;
        previewController.delegate = previewController;
        previewController.backBtnTitle = title;
        previewController.currentPreviewItemIndex = 0;
        previewController.hidesBottomBarWhenPushed = YES;
        [delegate.navigationController pushViewController:previewController animated:YES];
        [previewController release];
    }
}

@end
