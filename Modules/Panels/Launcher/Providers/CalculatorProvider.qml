import QtQuick
import Quickshell
import "../../../../Helpers/AdvancedMath.js" as AdvancedMath
import qs.Commons
import qs.Services.Keyboard
import qs.Services.UI
import qs.Services.Misc

Item {
  id: root

  // Provider metadata
  property string name: I18n.tr("launcher.providers.calculator")
  property var launcher: null
  property string iconMode: Settings.data.appLauncher.iconMode
  property bool handleSearch: true // Contribute to regular search
  property string supportedLayouts: "list"

  Connections {
    target: QalculateService
    function onEvalCompleted() {
      if (launcher) {
        launcher.updateResults();
      }
    }
  }

  // Initialize provider
  function init() {
    Logger.d("CalculatorProvider", "Initialized");
  }

  // Get search results - evaluates math expressions inline
  function getResults(query) {
    if (!query)
      return [];

    let trimmed = query.trim();
    if (!trimmed)
      return [];

    if (!trimmed.startsWith('='))
      return [];
    trimmed = trimmed.slice(1).trim();

    try {
      QalculateService.evaluate(trimmed);
      const formattedResult = QalculateService.result
      // Result is pending, output will be refreshed by connection
      if (!formattedResult)
        return [];
      return [
            {
              "name": formattedResult,
              "description": I18n.tr("launcher.providers.calculator-press-enter-to-copy"),
              "icon": iconMode === "tabler" ? "calculator" : "accessories-calculator",
              "isTablerIcon": true,
              "isImage": false,
              "provider": root,
              "onActivate": function () {
                // Copy result to clipboard via xclip
                const formattedResult = QalculateService.result;
                Quickshell.execDetached(["sh", "-c", "echo -n '" + formattedResult.replace(/'/g, "'\\''") + "' | wl-copy"]);
                ToastService.showNotice(I18n.tr("common.copied-to-clipboard"), formattedResult);
                if (launcher)
                  launcher.close();
              }
            }
          ];
    } catch (error) {
      return [];
    }
    return results;
  }

  // Check if a string is a valid math expression
  function isMathExpression(expr) {
    // Allow: digits, operators, parentheses, decimal points, whitespace, letters (for functions), commas
    if (!/^[\d\s\+\-\*\/\(\)\.\%\^a-zA-Z,]+$/.test(expr))
      return false;

    // Must contain at least one operator OR a function call (letter followed by parenthesis)
    if (!/[+\-*/%\^]/.test(expr) && !/[a-zA-Z]\s*\(/.test(expr))
      return false;

    // Reject if ends with an operator (incomplete expression)
    if (/[+\-*/%\^]\s*$/.test(expr))
      return false;

    // Reject if it's just letters (would match app names)
    if (/^[a-zA-Z\s]+$/.test(expr))
      return false;

    return true;
  }
}
