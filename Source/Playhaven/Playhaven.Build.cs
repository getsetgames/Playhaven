//
//  Created by Robert Segal on 2016-02-04.
//  Copyright (c) 2016 Get Set Games Inc. All rights reserved.
//

using System.IO;
using System.Diagnostics;

namespace UnrealBuildTool.Rules
{
	public class Playhaven : ModuleRules
	{
		private string ModulePath
		{
			get { return ModuleDirectory; }
		}

		public Playhaven(TargetInfo Target)
		{
			PublicIncludePaths.AddRange(
				new string[] {
					// ... add public include paths required here ...
				}
				);

			PrivateIncludePaths.AddRange(
				new string[] {
					"Developer/Playhaven/Private",
					// ... add other private include paths required here ...
				}
				);

			PublicDependencyModuleNames.AddRange(
				new string[]
				{
					"Core",
					"CoreUObject",
					"Engine"
					// ... add other public dependencies that you statically link with here ...
				}
				);

			PrivateDependencyModuleNames.AddRange(
				new string[]
				{
					// ... add private dependencies that you statically link with here ...
				}
				);

			DynamicallyLoadedModuleNames.AddRange(
				new string[]
				{
					// ... add any modules that your module loads dynamically here ...
				}
				);
				
			PrivateIncludePathModuleNames.AddRange(
			new string[] {
				"Settings"
			}
			);


			if (Target.Platform == UnrealTargetPlatform.IOS) {

				var XCodeProjectFile = Path.Combine(ModulePath,"..","..","lib","iOS","playhaven-sdk-ios.xcodeproj");

 				ProcessStartInfo info = new ProcessStartInfo("xcodebuild");

        		info.UseShellExecute = true;
        		info.Arguments       = "-project '" + XCodeProjectFile + "' -target PlayHaven";

        		Process.Start(info);

				var Lib = Path.Combine(ModulePath,"..","..","lib","iOS","build","Release-iphoneos","libPlayHaven.a");
				PublicAdditionalLibraries.Add(Lib);
			}
			else if(Target.Platform == UnrealTargetPlatform.Android)
			{
				string PluginPath = Utils.MakePathRelativeTo(ModuleDirectory, BuildConfiguration.RelativeEnginePath);
				AdditionalPropertiesForReceipt.Add(new ReceiptProperty("AndroidPlugin", Path.Combine(PluginPath, "Playhaven_APL.xml")));
			}
		}
	}
}
