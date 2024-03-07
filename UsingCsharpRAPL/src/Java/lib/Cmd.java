package JavaIPC;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

public enum Cmd {
    Unkown((byte)-3),
    Error((byte)-2),
    Stopped((byte)-1),
    Exit((byte)0),
    Go((byte)1),
    Done((byte)2),
    Ready((byte)3),
    Ok((byte)4);
    private static final Map<Byte, Cmd> VALUE_TO_ENUM_MAP;
    private final byte value;

    static {
        VALUE_TO_ENUM_MAP = new HashMap<>();
        for (Cmd type : EnumSet.allOf(Cmd.class)) {
            VALUE_TO_ENUM_MAP.put(type.value, type);
        }
    }

    private Cmd(byte value) {
        this.value = value;
    }

    public byte getValue() {
        return value;
    }
    public static Cmd forValue(byte value) {
        return VALUE_TO_ENUM_MAP.get(value);
    }
}