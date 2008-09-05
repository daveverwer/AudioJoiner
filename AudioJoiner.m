#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  NSString *outputFile = @"../../blackmessiah.m4a";
  NSMutableArray *inputFiles = [NSMutableArray arrayWithObjects:
                                @"../../blackmessiahintroduction.m4a",
                                @"../../blackmessiahlineup.m4a",
                                @"../../blackmessiahdiscography.m4a",
                                nil];
  
  // Get the working file name from the list of files
  NSString *firstInputFile = [inputFiles objectAtIndex:0];
  [inputFiles removeObjectAtIndex:0];
  
  // Ready to collect the chapter information
  NSMutableArray *chapterMarks = [NSMutableArray array];
  
  // Open the working file and mark it for editing
  NSError *errLoadFirstTrack = nil;
  QTMovie *workingTrack = [QTMovie movieWithFile:firstInputFile error:&errLoadFirstTrack];
  if (errLoadFirstTrack) NSLog(@"errLoadFirstTrack: %@", errLoadFirstTrack);
  [workingTrack setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];

  // Append the rest of the input files
  for (NSString *inputFile in inputFiles) {
    [chapterMarks addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSValue valueWithQTTime:[workingTrack duration]], QTMovieChapterStartTime,
                             [NSString stringWithFormat:@"Chapter %d", [inputFiles indexOfObject:inputFile]], QTMovieChapterName, nil]];
    // Load in the track
    NSError *errInputTrackLoad = nil;
    QTMovie *inputTrack = [QTMovie movieWithFile:inputFile error:&errInputTrackLoad];
    if (errInputTrackLoad) NSLog(@"errInputTrackLoad: %@", errInputTrackLoad);
    
    // Select all
    QTTime inputTrackDuration = [inputTrack duration];
    QTTime inputTrackBeginning = QTMakeTime(0, inputTrackDuration.timeScale);
    [inputTrack setSelection:QTMakeTimeRange(inputTrackBeginning, inputTrackDuration)];
    
    // Concatenate to the working track
    [workingTrack appendSelectionFromMovie:inputTrack];
  }
                              
  // Add the chapter marks to the working track
  NSError *errAddingChapters = nil;
  [workingTrack addChapters:chapterMarks withAttributes:[NSDictionary dictionary] error:&errAddingChapters];
  if (errAddingChapters) NSLog(@"errAddingChapters: %@", errAddingChapters);
  
  // Log that the chapters definitely exist at this point
  NSLog(@"Working Track Chapters\n%@", [workingTrack chapters]);

  // Write out the new track
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool:YES], QTMovieExport,
                         [NSNumber numberWithLong:kQTFileTypeMP4], QTMovieExportType, nil];
  [workingTrack writeToFile:outputFile withAttributes:attrs];
  
  // Reload the file to check for chapter markers
  QTMovie *reloadedTrack = [QTMovie movieWithFile:outputFile error:nil];
  NSLog(@"Reloaded Track Chapters\n%@", [reloadedTrack chapters]);
  NSLog(@"Reloaded Track Tracks\n%@", [reloadedTrack tracks]);

  [pool drain];
  return 0;
}
