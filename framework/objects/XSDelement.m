/*
 XSDelement.h
 The implementation of properties and methods for the XSDelement object.
 Generated by SudzC.com
 */
#import "XSDelement.h"
#import "XSDcomplexType.h"
#import "XSDschema.h"
#import "XMLUtils.h"
#import "XSSimpleType.h"
#import "XSDenumeration.h"

@interface XSDcomplexType (privateAccessors)
@property (strong, nonatomic) NSString *name;
@end

@interface XSDelement ()
@property (strong, nonatomic) XSDcomplexType* localComplexType;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* type;
@property (strong, nonatomic) NSString* substitutionGroup;
@property (strong, nonatomic) NSString* defaultValue;
@property (strong, nonatomic) NSString* fixed;
@property (strong, nonatomic) NSString* nillable;
@property (strong, nonatomic) NSString* abstractValue;
@property (strong, nonatomic) NSString* final;
@property (strong, nonatomic) NSString* block;
@property (strong, nonatomic) NSString* form;
@property (strong, nonatomic) NSNumber* minOccurs;
@property (strong, nonatomic) NSNumber* maxOccurs;
@end

@implementation XSDelement

- (id) initWithNode:(NSXMLElement*)node schema: (XSDschema*)schema {
    self = [super initWithNode:node schema:schema];
    if(self) {
        self.type = [XMLUtils node: node stringAttribute: @"type"];
        self.name = [XMLUtils node: node stringAttribute: @"name"];
        self.substitutionGroup = [XMLUtils node: node stringAttribute: @"substitutionGroup"];
        self.defaultValue = [XMLUtils node: node stringAttribute:  @"default"];
        self.fixed = [XMLUtils node: node stringAttribute: @"fixed"];
        self.nillable = [XMLUtils node: node stringAttribute: @"nillable"];
        self.abstractValue = [XMLUtils node: node stringAttribute: @"abstract"];
        self.final = [XMLUtils node: node stringAttribute: @"final"];
        self.block = [XMLUtils node: node stringAttribute: @"block"];
        self.form = [XMLUtils node: node stringAttribute: @"form"];

        NSNumberFormatter* numFormatter = [[NSNumberFormatter alloc] init];
        numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        NSString* minOccursValue = [XMLUtils node: node stringAttribute: @"minOccurs"];
        if(minOccursValue == nil) {
            self.minOccurs = [NSNumber numberWithInt: 1];
        } else if([minOccursValue isEqual: @"unbounded"]) {
            self.minOccurs = [NSNumber numberWithInt: -1];
        } else {
            self.minOccurs = [numFormatter numberFromString: minOccursValue];
        }
        
        NSString* maxOccursValue = [XMLUtils node: node stringAttribute: @"maxOccurs"];
        if(maxOccursValue == nil) {
            self.maxOccurs = [NSNumber numberWithInt: 1];
        } else if([maxOccursValue isEqual: @"unbounded"]) {
            self.maxOccurs = [NSNumber numberWithInt: -1];
        } else {
            self.maxOccurs = [numFormatter numberFromString: maxOccursValue];
        }
        
        /* If we do not have a type defined yet */
        if(self.type == nil) {
            /* Check if we have a complex type defined for the given element */
            NSXMLElement* complexTypeNode = [XMLUtils node:node childWithName:@"complexType"];
            if(complexTypeNode != nil) {
                self.localComplexType = [[XSDcomplexType alloc] initWithNode:complexTypeNode schema:schema];
                self.localComplexType.name = [self.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
                [schema addType: self.localComplexType];
            }
        }
    }
    return self;
}

- (BOOL) hasComplexType {
    return (self.type != nil && [[self.schema typeForName:self.type] isKindOfClass:[XSDcomplexType class]]);
}

- (NSString*) objcType {
    NSString* rtn;
    if([self isSingleValue]) {
        if(self.type != nil) {
            id<XSType> type =[self.schema typeForName:self.type];
            rtn = [type targetClassName];
        } else {
            rtn = [self.localComplexType targetClassName];
        }
    } else {
        if(self.type != nil) {
            rtn = [[self.schema typeForName:self.type] arrayType];
        } else {
            rtn = self.localComplexType.arrayType;
        }
    }
    
    return rtn;
}

- (id<XSType>) schemaType {
    if(self.type != nil) {
        return [self.schema typeForName: self.type];
    } else {
        return self.localComplexType;
    }
}

- (NSString*) variableName {
    return [XSDschema variableNameFromName:self.name multiple:!self.isSingleValue];
}

- (NSString*) variableClassName{
    NSString* rtn;
    
    NSArray* splitPrefix = [self.type componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @":"]];
    
    if(splitPrefix.count > 1) {
        rtn = (NSString*) [splitPrefix objectAtIndex: 1];
    }
    
    return rtn;
}


/* 
 * Name:        hasEnumeration
 * Parameters:  None
 * Returns:     BOOL value that will equate to 
 *              0 - NO - False.
 *              1 - YES - True
 * Description: Will check the current element to see if the element type is associated 
 *              with an enumeration values.
 */
- (BOOL) hasEnumeration{
    /* Initial Setup */
    BOOL isEnumeration = NO;
    /* Grab the type and check if it is of a simple type element */
    id <XSType> type = [self.schema typeForName:self.type];
    BOOL isSimpleType = [type isKindOfClass:[XSSimpleType class]];
    if(isSimpleType){
        /* Cast the object to the proper class and grab the count of enums */
        XSSimpleType* simpleTypeTemp = (XSSimpleType*) type;
        /* If we have some, set return value to yes */
        if([[simpleTypeTemp enumerations] count] > 0) {
            isEnumeration = YES;
        }
    }
    
    /* Return BOOL if we have enumerations */
    return isEnumeration;
}

- (NSArray*) enumerationValues{
    NSMutableArray *rtn = [[NSMutableArray alloc] init];
    /* Ensure that we have enumerations for this element */
    if(!self.hasEnumeration){
        return rtn;
    }
    
    /* Cast the type to the proper class */
    XSSimpleType* simpleType = (XSSimpleType*) [self.schema typeForName:self.type];

    /* Iterate through the enumerations to grab the value*/
    for (XSDenumeration* enumType in [simpleType enumerations]) {
        [rtn addObject:enumType.value];
    }
    
    /* Return the populated array of values */
    return rtn;
}

- (NSString *) buildEnumerationValues{
    NSString *rtn = [[self enumerationValues] componentsJoinedByString:@", "];
    return rtn;
}

- (NSString *) buildEnumerationNamesArray{
    NSString *rtn = @"";

    /* Check if we have enumerations for this type */
    if (![self hasEnumeration]) {
        return rtn;
    }
    
    /* Create the array with the proper format */
    for (NSString *enumValue in [self enumerationValues]) {
        rtn = [NSString stringWithFormat:@"%@, @\"%@\"", rtn, enumValue];
    }
    
    /* Remove the first two characters */
    rtn = [rtn substringFromIndex:2];
    
    return rtn;
}

- (NSString*) nameWithCapital {
    return [[self variableName] stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.name substringToIndex:1] uppercaseString]];
}

- (NSString*) readCodeForContent {
    NSString *rtn;
    
    /* Fetch the type and from those objects, call their appropriate method */
    if(self.localComplexType != nil) {
        rtn = [self.localComplexType readCodeForElement:self];
    }
    else if(self.hasEnumeration){
        /* Enumerations have no types defined, but have a base type. Grab the base type from the element and fetch the final code */
        XSSimpleType* simpleTypeTemp = (XSSimpleType*) [self.schema typeForName:self.type];
        rtn = [[self.schema typeForName:simpleTypeTemp.baseType] readCodeForElement:self];
        
        /* Insert comment into the code because we did not have any */
        if(!rtn){
            rtn = [NSString stringWithFormat:@"/* The types '%@' and '%@' are not found within the template schema. Please insert the correct simpleType accordingly */",
                   self.type, simpleTypeTemp.baseType];
        }
    }else {
        /* Fetch the type of the current element from the schema dictionaries and read the template code and generate final code */
        rtn = [[self.schema typeForName:self.type] readCodeForElement:self];
    }
    
    return rtn;
}

- (BOOL) isSingleValue {
    return [self.maxOccurs intValue] >= 0 && [self.maxOccurs intValue] <= 1;
}

@end