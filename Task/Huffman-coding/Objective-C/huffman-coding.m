#import <Foundation/Foundation.h>


@interface HuffmanTree : NSObject {
	int freq;
}
-(id)initWithFreq:(int)f;
@property (readonly) int freq;
@end

@implementation HuffmanTree
@synthesize freq; // the frequency of this tree
-(id)initWithFreq:(int)f {
	if (self = [super init]) {
		freq = f;
	}
	return self;
}
@end


const void *HuffmanRetain(CFAllocatorRef allocator, const void *ptr) {
	return [(id)ptr retain];
}
void HuffmanRelease(CFAllocatorRef allocator, const void *ptr) {
	[(id)ptr release];
}
CFComparisonResult HuffmanCompare(const void *ptr1, const void *ptr2, void *unused) {
	int f1 = ((HuffmanTree *)ptr1).freq;
	int f2 = ((HuffmanTree *)ptr2).freq;
	if (f1 == f2)
		return kCFCompareEqualTo;
	else if (f1 > f2)
		return kCFCompareGreaterThan;
	else
		return kCFCompareLessThan;
}


@interface HuffmanLeaf : HuffmanTree {
	char value; // the character this leaf represents
}
@property (readonly) char value;
-(id)initWithFreq:(int)f character:(char)c;
@end

@implementation HuffmanLeaf
@synthesize value;
-(id)initWithFreq:(int)f character:(char)c {
	if (self = [super initWithFreq:f]) {
		value = c;
	}
	return self;
}
@end


@interface HuffmanNode : HuffmanTree {
	HuffmanTree *left, *right; // subtrees
}
@property (readonly) HuffmanTree *left, *right;
-(id)initWithLeft:(HuffmanTree *)l right:(HuffmanTree *)r;
@end

@implementation HuffmanNode
@synthesize left, right;
-(id)initWithLeft:(HuffmanTree *)l right:(HuffmanTree *)r {
	if (self = [super initWithFreq:l.freq+r.freq]) {
		left = [l retain];
		right = [r retain];
	}
	return self;
}
-(void)dealloc {
	[left release];
	[right release];
	[super dealloc];
}
@end


HuffmanTree *buildTree(NSCountedSet *chars) {
	
	CFBinaryHeapCallBacks callBacks = {0, HuffmanRetain, HuffmanRelease, NULL, HuffmanCompare};
	CFBinaryHeapRef trees = CFBinaryHeapCreate(NULL, 0, &callBacks, NULL);

	// initially, we have a forest of leaves
	// one for each non-empty character
	for (NSNumber *ch in chars) {
		int freq = [chars countForObject:ch];
		if (freq > 0)
			CFBinaryHeapAddValue(trees, [[[HuffmanLeaf alloc] initWithFreq:freq character:(char)[ch intValue]] autorelease]);
	}
	
	NSCAssert(CFBinaryHeapGetCount(trees) > 0, @"String must have at least one character");
	// loop until there is only one tree left
	while (CFBinaryHeapGetCount(trees) > 1) {
		// two trees with least frequency
		HuffmanTree *a = (HuffmanTree *)CFBinaryHeapGetMinimum(trees);
		CFBinaryHeapRemoveMinimumValue(trees);
		HuffmanTree *b = (HuffmanTree *)CFBinaryHeapGetMinimum(trees);
		CFBinaryHeapRemoveMinimumValue(trees);
		
		// put into new node and re-insert into queue
		CFBinaryHeapAddValue(trees, [[[HuffmanNode alloc] initWithLeft:a right:b] autorelease]);
	}
	HuffmanTree *result = [(HuffmanTree *)CFBinaryHeapGetMinimum(trees) retain];
	CFRelease(trees);
	return [result autorelease];
}

void printCodes(HuffmanTree *tree, NSMutableString *prefix) {
	NSCAssert(tree != nil, @"tree must not be nil");
	if ([tree isKindOfClass:[HuffmanLeaf class]]) {
		HuffmanLeaf *leaf = (HuffmanLeaf *)tree;
		
		// print out character, frequency, and code for this leaf (which is just the prefix)
		NSLog(@"%c\t%d\t%@", leaf.value, leaf.freq, prefix);
		
	} else if ([tree isKindOfClass:[HuffmanNode class]]) {
		HuffmanNode *node = (HuffmanNode *)tree;
		
		// traverse left
		[prefix appendString:@"0"];
		printCodes(node.left, prefix);
		[prefix deleteCharactersInRange:NSMakeRange([prefix length]-1, 1)];
		
		// traverse right
		[prefix appendString:@"1"];
		printCodes(node.right, prefix);
		[prefix deleteCharactersInRange:NSMakeRange([prefix length]-1, 1)];
	}
}

int main(int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSString *test = @"this is an example for huffman encoding";
	
	// read each character and record the frequencies
	NSCountedSet *chars = [[NSCountedSet alloc] init];
	int n = [test length];
	for (int i = 0; i < n; i++)
		[chars addObject:[NSNumber numberWithInt:[test characterAtIndex:i]]];
	
	// build tree
	HuffmanTree *tree = buildTree(chars);
	[chars release];
	
	// print out results
	NSLog(@"SYMBOL\tWEIGHT\tHUFFMAN CODE");
	printCodes(tree, [NSMutableString string]);
	
    [pool drain];
    return 0;
}
