//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2015 Get Set Games Inc. All rights reserved.
//

#include "PlayhavenSettings.h"
#include "PlayhavenPrivatePCH.h"

UPlayhavenSettings::UPlayhavenSettings(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer),
PlayhavenTokeniOS(""),
PlayhavenSecretiOS(""),
PlayhavenTokenAndroid(""),
PlayhavenSecretAndroid("")
{
}
