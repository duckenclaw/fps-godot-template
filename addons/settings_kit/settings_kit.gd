@tool
extends EditorPlugin
## Settings Kit editor plugin.
##
## This is a library addon: it ships the SettingsManager base class and the
## RebindContainer UI scene for your scripts/scenes to use directly, so there is
## nothing to auto-register here. The plugin entry exists only so the addon can
## be enabled/disabled from Project Settings and published to the Asset Library.
##
## Your game registers its own settings autoload (a subclass of SettingsManager);
## this addon intentionally does not add one, so each project keeps its own
## action list and any genre-specific apply logic.
