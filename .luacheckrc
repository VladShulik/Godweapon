std = "lua51"

unused_args = false
unused_secondaries = false
unused_locals = false
unused_upvalues = false
max_line_length = false
redefined_globals = false

ignore = {
    "211",
    "212",
    "213",
    "311",
    "411",
    "412",
    "421",
    "431",
    "432",
    "433",
    "542",
    "621"
}

globals = {
    DEVPLAT_INIT_FINISHED = {read_only = false},
    Register = {read_only = false},
    Get = {read_only = false},
    GetStored = {read_only = false},
    GetList = {read_only = false},
    IsBasedOn = {read_only = false},
    OnLoaded = {read_only = false},
    IsValid = {read_only = false},
    hook = {
        read_only = false,
        fields = {
            Add = {read_only = false},
            Remove = {read_only = false},
            Run = {read_only = false},
            Call = {read_only = false},
            GetTable = {read_only = false},
        }
    },
    GAMEMODE = {
        read_only = false,
        fields = {
            AddDeathNotice = {read_only = false},
            EntityTakeDamage = {read_only = false},
            EntityRemoved = {read_only = false}
        }
    },
    timeStopDataStates = {read_only = false},
    timeStopData = {read_only = false},
    timestopN = {read_only = false},
    oldTimestop = {read_only = false},
    modeList = {read_only = false},
    tab = {read_only = false}
}

read_globals = {
    "AddCSLuaFile",
    "Angle",
    "AddOriginToPVS",
    "ACT_VM_PRIMARYATTACK",
    "CHAN_AUTO",
    "CHAN_VOICE_BASE",
    "CLIENT",
    "COLLISION_GROUP_PROJECTILE",
    "COLLISION_GROUP_DEBRIS",
    "Color",
    "CurTime",
    "DamageInfo",
    "DrGBase",
    "DynamicLight",
    "EffectData",
    "FILL",
    "FindMetaTable",
    "HSVToColor",
    "HUD_PRINTCENTER",
    "IsValid",
    "LocalPlayer",
    "Material",
    "Msg",
    "MsgC",
    "ParticleEmitter",
    "RunConsoleCommand",
    "SERVER",
    "ScreenScale",
    "Sound",
    "TEXT_ALIGN_CENTER",
    "TEXT_ALIGN_LEFT",
    "TEXT_ALIGN_TOP",
    "TOP",
    "BOTTOM",
    "Vector",
    "baseclass",
    "color_white",
    "concommand",
    "draw",
    "duplicator",
    "engine",
    "ents",
    "file",
    "game",
    "gamemode",
    "halo",
    "include",
    "isbool",
    "isentity",
    "isfunction",
    "isstring",
    "istable",
    "language",
    "list",
    "net",
    "notification",
    "player",
    "surface",
    "system",
    "timer",
    "undo",
    "util",
    "vgui",
    "weapons",
    "bit",
    "DMG_BULLET",
    "DMG_BLAST",
    "D_LI",
    "D_NU",
    "D_HT",
    "ScreenShake",
    "CreateSound"
}

read_globals["string"] = {
    fields = {
        TrimLeft = {},
        TrimRight = {},
        EndsWith = {},
        StartWith = {},
        ToColor = {}
    }
}

read_globals["table"] = {
    fields = {
        Copy = {},
        RemoveByValue = {},
        HasValue = {},
        Random = {},
        Merge = {}
    }
}

