//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

#pragma once

#include "PlayhavenSettings.generated.h"

UCLASS(config = Engine, defaultconfig)
class UPlayhavenSettings : public UObject
{
	GENERATED_BODY()
	
public:
	UPlayhavenSettings(const FObjectInitializer& ObjectInitializer);
};
