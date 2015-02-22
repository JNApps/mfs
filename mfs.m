// MFS | Map File Structure
// Copyright (c) 2015 Joseph Newton
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/Jnewto32/MFS

#pragma mark - Imports and Definitions

#import <Foundation/Foundation.h>
#import <getopt.h>
#import <unistd.h>

#define MFS_VERSION "1.0"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark - Function Declarations and Global Variables
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

id contentsOfPath(NSString *path);
void printPathContentsToFile(NSString *path, FILE *output, NSString *prefix);

NSFileManager *gManager;

NSString *fileName = @"FileStructure.plist";
NSString *prefixString = @"\t";
NSString *inputPath = nil;
NSString *outputPath = nil;

BOOL includeFilesWithPrefix = NO;
BOOL includeFileExtensions = YES;
BOOL printToConsole = NO;
BOOL writeToTextFile = NO, appendTextFile = NO;
BOOL longOutput = NO;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark - Usage
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

void print_usage() { //You screwed up, here's how to use this really simple tool...
    fprintf(stderr,
            "\nmfs %s\n"
            "Map File Structure\n"
            "Usage: mfs [options] -i <inputDirectory>\n"
            "\n"
            "Available Options:\n"
            "Required:\n"
            "       -i, --input             input directory\n"
            "Optional:\n"
            "       -o, --output            output directory. If not specified, input directory will be\n"
            "                               used for writing out files\n"
            "       -n, --filename          file name. Default is \"FileStructure.plist (or .txt)\"\n"
            "       -p, --includeHidden     include files with '.' prefix\n"
            "       -x, --noExtensions      remove file extensions\n"
            "       -h, --help              print this help message\n"
            "       -c, --printConsole      print file structure to console in lieu of outputting to\n"
            "                               file. The output directory, if included, is ignored.\n"
            "       -l, --long              used with -a option. Print full directory with each output.\n"
            "                               --prefix option is ignored when using this option\n"
            "       -t, --text              output to text file\n"
            "           --append            when writing to a text file, include this option to append\n"
            "                               the file in lieu of overwriting (default).\n"
            "           --prefix            the prefix to use when writing to console. Default is \"\\t\"\n\n"
            , MFS_VERSION);
}

//Long argument parser
static int ap = 0, px = 0;
static struct option long_options[] = {
    {"input",           required_argument,  0, 'i'},
    {"output",          required_argument,  0, 'o'},
    {"filename",        required_argument,  0, 'n'},
    {"includeHidden",   no_argument,        0, 'p'},
    {"noExtensions",    no_argument,        0, 'x'},
    {"help",            no_argument,        0, 'h'},
    {"printConsole",    no_argument,        0, 'c'},
    {"long",            no_argument,        0, 'l'},
    {"text",            no_argument,        0, 't'},
    {"append",          no_argument,        &ap, 1},
    {"prefix",          required_argument,  &px, 1},
    {0, 0, 0, 0}
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark - Main
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

int main(int argc, char *argv[]) {
    @autoreleasepool {
        gManager = [[NSFileManager alloc] init]; //Our file manager. We make it global in our main funciton. It's easier that way..
        int arg, argIdx = 0;
        
#pragma mark Parse Arguments
        //Let's use our handy dandy getopt friend to parse our arguments.
        while ((arg = getopt_long(argc, argv, "i:o:n:pxhclt", long_options, &argIdx)) != -1) {
            switch (arg) {
                case 'i':
                    inputPath = [[NSString stringWithUTF8String:optarg] stringByExpandingTildeInPath];
                    break;
                case 'o':
                    outputPath = [[NSString stringWithUTF8String:optarg] stringByExpandingTildeInPath];
                    break;
                case 'n':
                    fileName = [NSString stringWithUTF8String:optarg];
                    break;
                case 'p':
                    includeFilesWithPrefix = YES;
                    break;
                case 'x':
                    includeFileExtensions = NO;
                    break;
                case 'h':
                    print_usage();
                    exit(0);
                case 'c':
                    printToConsole = YES;
                    break;
                case 'l':
                    longOutput = YES;
                    break;
                case 't':
                    writeToTextFile = YES;
                    break;
                case 0:
                    if (strcmp("append", long_options[argIdx].name) == 0 && ap == 1) {
                        appendTextFile = YES;
                    }
                    else if (strcmp("prefix", long_options[argIdx].name) == 0 && px == 1 && optarg) {
                        prefixString = [NSString stringWithUTF8String:optarg];
                    }
                default:
                    break;
            }
        }
        
#pragma mark Validate Directories
        if (!writeToTextFile && [[fileName pathExtension] compare:@"txt" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            writeToTextFile = YES; //If you specified a file name with a .txt extension, it will write to that file
        }
        
        if (inputPath == nil) {
            fprintf(stderr, "No input directory specified\n"); //... I told you that you needed this parameter
            print_usage();
            exit(0);
        }
        
        if (![gManager fileExistsAtPath:inputPath isDirectory:NULL]) {
            fprintf(stderr, "Invalid input directory entered.\n"); //Common, give me a real input path...
            print_usage(); //Cause you obviously don't know how to use this yet..
            exit(0);
        }
        
        if (outputPath == nil) {
            outputPath = inputPath;
        }
        else {
            if (![gManager fileExistsAtPath:outputPath isDirectory:NULL]) {
                fprintf(stderr, "Invalid output directory entered.\n"); //The output path too? Really..?
                print_usage(); //Cause you obviously don't know how to use this yet..
                exit(0);
            }
        }
        
#pragma mark Console
        if (printToConsole) { //We only need the input path if we're outputting to console
            if (longOutput) {
                printPathContentsToFile(inputPath, stdout, inputPath); //If we're outputting with long format, the we prefix everything with the full path
            }
            else {
                fprintf(stdout, "%s:\n\n", [inputPath UTF8String]);
                printPathContentsToFile(inputPath, stdout, nil); //No prefix needed since this is the root folder of the mapping
            }
        }
#pragma mark Text
        if (writeToTextFile) {
            fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"]; //In case you don't give your own file name
            FILE *textFile = NULL;
            if (appendTextFile) {
                textFile = fopen([[outputPath stringByAppendingPathComponent:fileName] fileSystemRepresentation], "a"); //The text file.
            }
            else {
                textFile = fopen([[outputPath stringByAppendingPathComponent:fileName] fileSystemRepresentation], "w"); //The text file.
            }
            if (textFile == NULL) {
                fprintf(stderr, "Could not open text file (%s) for writing", [fileName UTF8String]); //...What did you do wrong?
                exit(0);
            }
            else {
                if (longOutput) {
                    printPathContentsToFile(inputPath, textFile, inputPath); //If we're outputting with long format, the we prefix everything with the full path
                }
                else {
                    fprintf(textFile, "%s:\n\n", [inputPath UTF8String]);
                    printPathContentsToFile(inputPath, textFile, nil); //No prefix needed since this is the root folder of the mapping
                }
            }
            fclose(textFile); //No memory leaks please
        }
#pragma mark Plist
        if (!writeToTextFile && !printToConsole) { //We only need to do these things if we're outputting to a file
            NSDictionary *masterDict = contentsOfPath(inputPath); //Get the contents, duh!
            
            fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"]; //In case you enter an incorrect extension.
            [masterDict writeToFile:[outputPath stringByAppendingPathComponent:fileName] atomically:YES]; //Save it!
        }
    }
    
    return 0;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark - Map File Structure - Plist
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

//Recursive function that maps out the entire file structure
NSDictionary *contentsOfPath(NSString *path) {
    NSArray *contents = [gManager contentsOfDirectoryAtPath:path error:nil]; //Array of all folders and files
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:contents.count]; //Our lovely little container
    
    BOOL hasFolder = NO; //Used later, be patient
    
    for (int i = 0; i < contents.count; i++) {
        NSString *file = [contents objectAtIndex:i];
        if (!includeFilesWithPrefix && [file hasPrefix:@"."]) { //If the file starts with a "." and we don't want it then skip it
            continue;
        }
        NSString *newPath = [path stringByAppendingPathComponent:file]; //Full file path
        BOOL isFolder;
        [gManager fileExistsAtPath:newPath isDirectory:&isFolder]; //This is really to only check if it's a folder
        if (isFolder) {
            hasFolder = YES;
            NSObject *obj = contentsOfPath(newPath); //If it's a folder, then get the dictionary of it's branch
            if (obj) {
                [dict setObject:obj forKey:file]; //If we get a valid object back, then throw it in our container
            }
            else {
                if (includeFileExtensions) {
                    [dict setObject:file forKey:file]; //If for some reason we don't get an object back then just add the file name for the key and value
                }
                else {
                    [dict setObject:[file stringByDeletingPathExtension] forKey:[file stringByDeletingPathExtension]];
                }
            }
        }
        else {
            if (includeFileExtensions) {
                [dict setObject:file forKey:file]; //If this is a file, not a folder, then add its name for the key and value
            }
            else {
                [dict setObject:[file stringByDeletingPathExtension] forKey:[file stringByDeletingPathExtension]];
            }
        }
    }
    
    if (!hasFolder) { //Told you it would be used. If the directory only has files, no folders, return an array in lieu of a dictionary; it looks nicer
        NSArray *objects = [dict allValues];
        return [objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString *)obj1 compare:(NSString *)obj2 options:NSCaseInsensitiveSearch];
        }];
    }
    
    return dict; //Return our container. Did you expect something different?
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#pragma mark - Map File Structure - Console/Text
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

void printPathContentsToFile(NSString *path, FILE *output, NSString *prefix) { //Used to output to console. We have a separate function from "contentsOfPath" to speed things up
    NSArray *contents = [gManager contentsOfDirectoryAtPath:path error:nil]; //Array of all folders and files, again
    
    for (int i = 0; i < contents.count; i++) {
        NSString *file = [contents objectAtIndex:i];
        if ([file hasPrefix:@"."] && !includeFilesWithPrefix) { //If the file starts with a "." and we don't want it then skip it
            continue;
        }
        NSString *newPath = [path stringByAppendingPathComponent:file]; //Full file path
        BOOL isFolder;
        [gManager fileExistsAtPath:newPath isDirectory:&isFolder]; //This is really to only check if it's a folder
        if (isFolder) {
            if (longOutput) {
                printPathContentsToFile(newPath, output, newPath);
            }
            else {
                if (prefix) {
                    NSMutableString *str = [NSMutableString stringWithString:prefix];
                    [str appendString:prefixString]; //Since we're diving into a subdirectory, the prefix needs to be appended
                    fprintf(output, "%s%s\n", [prefix UTF8String], [file UTF8String]); //Print the folder name
                    printPathContentsToFile(newPath, output, [NSString stringWithString:str]);
                }
                else {
                    fprintf(output, "%s\n", (includeFileExtensions? [file UTF8String] : [[file stringByDeletingPathExtension] UTF8String]));
                    printPathContentsToFile(newPath, output, prefixString);
                }
            }
        }
        else {
            if (longOutput) {
                fprintf(output, "%s\n", (includeFileExtensions? [newPath UTF8String] : [[newPath stringByDeletingPathExtension] UTF8String])); //Print out the full path
            }
            else {
                if (prefix) {
                    fprintf(output, "%s%s\n", [prefix UTF8String], (includeFileExtensions? [file UTF8String] : [[file stringByDeletingPathExtension] UTF8String])); //Print prefix and file name
                }
                else {
                    fprintf(output, "%s\n", (includeFileExtensions? [file UTF8String] : [[file stringByDeletingPathExtension] UTF8String])); //Print just file name (this is the root folder of the mapping)
                }
            }
        }
    }
}

