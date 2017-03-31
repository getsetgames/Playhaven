//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

#pragma once

#include "UObject/Object.h"
#include "UObject/ScriptMacros.h"
#include "PlayhavenSettings.generated.h"

UCLASS(config = Engine, defaultconfig)
class UPlayhavenSettings : public UObject
{
	GENERATED_BODY()
	
public:
	UPlayhavenSettings(const FObjectInitializer& ObjectInitializer);
    
    UPROPERTY(Config, EditAnywhere, Category=General, meta=(DisplayName="Token - iOS"))
    FString PlayhavenTokeniOS;
    
    UPROPERTY(Config, EditAnywhere, Category=General, meta=(DisplayName="Secret - iOS"))
    FString PlayhavenSecretiOS;
    
    UPROPERTY(Config, EditAnywhere, Category=General, meta=(DisplayName="Token - Android"))
    FString PlayhavenTokenAndroid;
    
    UPROPERTY(Config, EditAnywhere, Category=General, meta=(DisplayName="Secret - Android"))
    FString PlayhavenSecretAndroid;
};
