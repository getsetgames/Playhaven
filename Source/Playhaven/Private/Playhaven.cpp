//
//  Created by Robert Segal on 2016-03-31.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

#include "PlayhavenPrivatePCH.h"
#include "PlayhavenSettings.h"
#include "ISettingsModule.h"

DEFINE_LOG_CATEGORY(LogPlayhaven);

#define LOCTEXT_NAMESPACE "Playhaven"

class FPlayhaven : public IPlayhaven
{
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
};

IMPLEMENT_MODULE( FPlayhaven, Playhaven )

void FPlayhaven::StartupModule()
{
	// register settings
	if (ISettingsModule* SettingsModule = FModuleManager::GetModulePtr<ISettingsModule>("Settings"))
	{
		SettingsModule->RegisterSettings("Project", "Plugins", "Playhaven",
										 LOCTEXT("RuntimeSettingsName", "Playhaven"),
										 LOCTEXT("RuntimeSettingsDescription", "Configure the Playhaven plugin"),
										 GetMutableDefault<UPlayhavenSettings>()
										 );
	}
}


void FPlayhaven::ShutdownModule()
{
	// This function may be called during shutdown to clean up your module.  For modules that support dynamic reloading,
	// we call this function before unloading the module.
}

#undef LOCTEXT_NAMESPACE
