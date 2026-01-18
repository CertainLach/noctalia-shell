pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root

    property bool active: Settings.isLoaded
    property bool loading: false
    property bool waitingForEval: true

    property var lastExpr: null
    property var result: null

    signal evalCompleted

    Process {
        id: evalProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            waitingForEval = false;
            loading = false;
            if (exitCode !== 0) {
                result = String(stderr.text);
                return;
            }
            result = String(stdout.text);
            root.evalCompleted();
        }
    }

    function evaluate(expr) {
        if (expr == lastExpr) {
            return;
        }
        lastExpr = expr;
        loading = true;
        waitingForEval = true;
        evalProc.command = ["qalc", "--", expr];
        evalProc.running = true;
    }
}
