%% @author Loïc Hoguin <essen@dev-extend.eu>
%% @copyright 2010-2011 Loïc Hoguin.
%% @doc General character functions.
%%
%%	This file is part of EGS.
%%
%%	EGS is free software: you can redistribute it and/or modify
%%	it under the terms of the GNU Affero General Public License as
%%	published by the Free Software Foundation, either version 3 of the
%%	License, or (at your option) any later version.
%%
%%	EGS is distributed in the hope that it will be useful,
%%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%	GNU Affero General Public License for more details.
%%
%%	You should have received a copy of the GNU Affero General Public License
%%	along with EGS.  If not, see <http://www.gnu.org/licenses/>.

-module(psu_characters).
-export([
	character_tuple_to_binary/1, character_user_to_binary/1, class_atom_to_binary/1, class_binary_to_atom/1,
	gender_atom_to_binary/1, gender_binary_to_atom/1, options_binary_to_tuple/1, options_tuple_to_binary/1,
	race_atom_to_binary/1, race_binary_to_atom/1, stats_tuple_to_binary/1
]).

-include("include/records.hrl").

%% @doc Convert a character tuple into a binary to be sent to clients.
%%      Only contains the actually saved data, not the stats and related information.
%% @todo The name isn't very good anymore now that I switched #characters to #users.
character_tuple_to_binary(Tuple) ->
	#users{name=Name, race=Race, gender=Gender, class=Class, appearance=Appearance} = Tuple,
	RaceBin = race_atom_to_binary(Race),
	GenderBin = gender_atom_to_binary(Gender),
	ClassBin = class_atom_to_binary(Class),
	AppearanceBin = psu_appearance:tuple_to_binary(Race, Appearance),
	LevelsBin = egs_proto:build_char_level(Tuple),
	<< Name/binary, RaceBin:8, GenderBin:8, ClassBin:8, AppearanceBin/binary, LevelsBin/binary >>.

%% @doc Convert a character tuple into a binary to be sent to clients.
%%      Contains everything from character_tuple_to_binary/1 along with location, stats, SE and more.
%% @todo The second StatsBin seems unused. Not sure what it's for.
%% @todo Find out what the big block of 0 is at the end.
%% @todo The value before IntDir seems to be the player's current animation. 01 stand up, 08 ?, 17 normal sit

character_user_to_binary(User) ->
	#users{gid=CharGID, lid=CharLID, npcid=NPCid, type=Type, level=Level, stats=Stats, currenthp=CurrentHP, maxhp=MaxHP,
		pos={X, Y, Z, Dir}, area={QuestID, ZoneID, MapID}, entryid=EntryID, prev_area={PrevQuestID, PrevZoneID, PrevMapID}, prev_entryid=PrevEntryID} = User,
	CharBin = psu_characters:character_tuple_to_binary(User),
	StatsBin = psu_characters:stats_tuple_to_binary(Stats),
	EXPNextLevel = 100,
	EXPCurrentLevel = 0,
	IntDir = trunc(Dir * 182.0416),
	TypeID = case Type of npc -> 16#00001d00; _ -> 16#00001200 end,
	NPCStuff = case Type of npc -> 16#01ff; _ -> 16#0000 end,
	<<	TypeID:32, CharGID:32/little, 0:64, CharLID:16/little, 0:16, NPCStuff:16, NPCid:16/little, QuestID:32/little,
		ZoneID:32/little, MapID:32/little, EntryID:16/little, 0:16,
		16#0100:16, IntDir:16/little, X:32/little-float, Y:32/little-float, Z:32/little-float, 0:64,
		PrevQuestID:32/little, PrevZoneID:32/little, PrevMapID:32/little, PrevEntryID:32/little,
		CharBin/binary, EXPNextLevel:32/little, EXPCurrentLevel:32/little, MaxHP:32/little,
		StatsBin/binary, 0:96, Level:32/little, StatsBin/binary, CurrentHP:32/little, MaxHP:32/little,
		0:1344, 16#0000803f:32, 0:64, 16#0000803f:32, 0:64, 16#0000803f:32, 0:64, 16#0000803f:32, 0:64, 16#0000803f:32, 0:160, 16#0000803f:32, 0:352 >>.

%% @doc Convert a class atom into a binary to be sent to clients.

class_atom_to_binary(Class) ->
	case Class of
		hunter			-> 0;
		ranger			-> 1;
		force			-> 2;
		fighgunner		-> 3;
		guntecher		-> 4;
		wartecher		-> 5;
		fortefighter	-> 6;
		fortegunner		-> 7;
		fortetecher		-> 8;
		protranser		-> 9;
		acrofighter		-> 10;
		acrotecher		-> 11;
		fighmaster		-> 12;
		gunmaster		-> 13;
		masterforce		-> 14;
		acromaster		-> 15
	end.

%% @doc Convert the binary class to an atom.
%% @todo Probably can make a list and use that list for both functions.

class_binary_to_atom(ClassBin) ->
	case ClassBin of
		 0 -> hunter;
		 1 -> ranger;
		 2 -> force;
		 3 -> fighgunner;
		 4 -> guntecher;
		 5 -> wartecher;
		 6 -> fortefighter;
		 7 -> fortegunner;
		 8 -> fortetecher;
		 9 -> protranser;
		10 -> acrofighter;
		11 -> acrotecher;
		12 -> fighmaster;
		13 -> gunmaster;
		14 -> masterforce;
		15 -> acromaster
	end.

%% @doc Convert a gender atom into a binary to be sent to clients.

gender_atom_to_binary(Gender) ->
	case Gender of
		male	-> 0;
		female	-> 1
	end.

%% @doc Convert the binary gender into an atom.

gender_binary_to_atom(GenderBin) ->
	case GenderBin of
		0 -> male;
		1 -> female
	end.

%% @doc Convert the binary options data into a tuple.
%%      The few unknown values are probably PS2 or 360 only.

options_binary_to_tuple(Binary) ->
	<<	TextDisplaySpeed:8, Sound:8, MusicVolume:8, SoundEffectVolume:8, Vibration:8, RadarMapDisplay:8,
		CutInDisplay:8, MainMenuCursorPosition:8, _:8, Camera3rdY:8, Camera3rdX:8, Camera1stY:8, Camera1stX:8,
		Controller:8, WeaponSwap:8, LockOn:8, Brightness:8, FunctionKeySetting:8, _:8, ButtonDetailDisplay:8, _:32 >> = Binary,
	{options, TextDisplaySpeed, Sound, MusicVolume, SoundEffectVolume, Vibration, RadarMapDisplay,
		CutInDisplay, MainMenuCursorPosition, Camera3rdY, Camera3rdX, Camera1stY, Camera1stX,
		Controller, WeaponSwap, LockOn, Brightness, FunctionKeySetting, ButtonDetailDisplay}.

%% @doc Convert a tuple of options data into a binary to be sent to clients.

options_tuple_to_binary(Tuple) ->
	{options, TextDisplaySpeed, Sound, MusicVolume, SoundEffectVolume, Vibration, RadarMapDisplay,
		CutInDisplay, MainMenuCursorPosition, Camera3rdY, Camera3rdX, Camera1stY, Camera1stX,
		Controller, WeaponSwap, LockOn, Brightness, FunctionKeySetting, ButtonDetailDisplay} = Tuple,
	<<	TextDisplaySpeed, Sound, MusicVolume, SoundEffectVolume, Vibration, RadarMapDisplay,
		CutInDisplay, MainMenuCursorPosition, 0, Camera3rdY, Camera3rdX, Camera1stY, Camera1stX,
		Controller, WeaponSwap, LockOn, Brightness, FunctionKeySetting, 0, ButtonDetailDisplay, 0:32 >>.

%% @doc Convert a race atom into a binary to be sent to clients.

race_atom_to_binary(Race) ->
	case Race of
		human	-> 0;
		newman	-> 1;
		cast	-> 2;
		beast	-> 3
	end.

%% @doc Convert the binary race into an atom.

race_binary_to_atom(RaceBin) ->
	case RaceBin of
		0 -> human;
		1 -> newman;
		2 -> cast;
		3 -> beast
	end.

%% @doc Convert the tuple of stats data into a binary to be sent to clients.

stats_tuple_to_binary(Tuple) ->
	{stats, ATP, ATA, TP, DFP, EVP, MST, STA} = Tuple,
	<<	ATP:16/little, DFP:16/little, ATA:16/little, EVP:16/little,
		STA:16/little, 0:16, TP:16/little, MST:16/little >>.
