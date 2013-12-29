var InspectorBackendStub = new Object();

InspectorBackendStub.evaluate = function(expression, objectGroup, includeCommandLineAPI, evalCallback) {
	var result = NWTConsoleBackend.evaluate_objectGroup_includeCommandLineAPI_(expression, objectGroup, includeCommandLineAPI);
	evalCallback(JSON.parse(result));
};

InspectorBackendStub.getCompletions = function(expressionString, includeCommandLineAPI, reportCompletions) {
	var result = NWTConsoleBackend.completionsForExpression_includeCommandLineAPI_(expressionString, includeCommandLineAPI);
	reportCompletions(JSON.parse(result));
};

InspectorBackendStub.getProperties = function(objectId, ignoreHasOwnProperty, abbreviate, callback) {
	var result = NWTConsoleBackend.propertiesForObjectWithId_ignoringHasOwnProperty_abbreviate_(objectId, ignoreHasOwnProperty, abbreviate);
	callback(JSON.parse(result));
};

InspectorBackendStub.setPropertyValue = function(objectId, name, value, callback) {
	var result = NWTConsoleBackend.setValue_forKey_ofPropertyWithId_(value, name, objectId);
	callback(JSON.parse(result));
}

InspectorBackendStub.setPropertyText = function(id, index, text, something, callback) {
	var result = NWTConsoleBackend.setValue_forKey_ofPropertyWithId_(value, name, objectId);
	callback(JSON.parse(result));	
}

InspectorBackendStub.setTextNodeValue = function(nodeId, text, callback) {
	var result = NWTConsoleBackend.setValue_forKey_ofPropertyWithId_(value, name, objectId);
	callback(JSON.parse(result));
}

InspectorBackendStub.setAttribute = function(nodeId, name, value, mycallback) {
	var result = NWTConsoleBackend.setValue_forKey_ofPropertyWithId_(value, name, objectId);
	callback(JSON.parse(result));
}

InspectorBackendStub.activateBreakpoints = function() {}
InspectorBackendStub.addInspectedNode = function(nodeId) {}
InspectorBackendStub.addRule = function(nodeId, selector, callback) {}
InspectorBackendStub.addScriptToEvaluateOnLoad = function(script) {}
InspectorBackendStub.cachedResources = function(callback) {}
InspectorBackendStub.changeTagName = function(nodeId, newText, changeTagNameCallback) {}
InspectorBackendStub.clearConsoleMessages = function() {}
InspectorBackendStub.clearProfiles = function() {}
InspectorBackendStub.continueToLocation = function(sourceID, lineNumber, columnNumber) {}
InspectorBackendStub.copyNode = function(nodeId) {}
InspectorBackendStub.deactivateBreakpoints = function() {}
InspectorBackendStub.deleteCookie = function(name, domain) {}
InspectorBackendStub.didEvaluateForTestInFrontend = function(callId, message) {}
InspectorBackendStub.disableDebugger = function() {}
InspectorBackendStub.disableProfiler = function(disable) {}
InspectorBackendStub.dispatch = function(message) {}
InspectorBackendStub.editScriptSource = function(sourceID, scriptSource, didEditScriptSource) {}
InspectorBackendStub.enableDebugger = function() {}
InspectorBackendStub.enableProfiler = function() {}
InspectorBackendStub.evaluateOnCallFrame = function(callFrameId, code, objectGroup, includeCommandLineAPI, updatingCallbackWrapper) {}
InspectorBackendStub.evaluateOnSelf = function(expression, args, callback) {}
InspectorBackendStub.executeSQL = function(id, query, callback) {}
InspectorBackendStub.getAllStyles = function(allStylesCallback) {}
InspectorBackendStub.getApplicationCaches = function(mycallback) {}
InspectorBackendStub.getChildNodes = function(parentid, mycallback) {}
InspectorBackendStub.getCompletionsOnCallFrame = function(selectedCallFrameId, expressionString, includeCommandLineAPI, reportCompletions) {}
InspectorBackendStub.getComputedStyleForNode = function(nodeId, callback) {}
InspectorBackendStub.getCookies = function(mycallback) {}
InspectorBackendStub.getDOMStorageEntries = function(id, callback) {}
InspectorBackendStub.getDatabaseTableNames = function(id, sortingCallback) {}
InspectorBackendStub.getEventListenersForNode = function(nodeId, callback) {}
InspectorBackendStub.getInlineStyleForNode = function(nodeId, callback) {}
InspectorBackendStub.getNodeProperties = function(nodeId, properties, setTooltip) {}
InspectorBackendStub.getNodePrototypes = function(nodeId, callback) {}
InspectorBackendStub.getOuterHTML = function(nodeId, startEditingAsHTML) {}
InspectorBackendStub.getProfile = function(typeId, uid, profileCallback) {}
InspectorBackendStub.getProfileHeaders = function(populateCallback) {}
InspectorBackendStub.getScriptSource = function(sourceID, didGetScriptSource) {}
InspectorBackendStub.getStyleSheet = function(styleSheetId, callback) {}
InspectorBackendStub.getStyleSheetText = function(styleSheetId, callback) {}
InspectorBackendStub.getStylesForNode = function(nodeId, callback) {}
InspectorBackendStub.getSupportedCSSProperties = function(propertyNamesCallback) {}
InspectorBackendStub.hideDOMNodeHighlight = function() {}
InspectorBackendStub.hideFrameHighlight = function() {}
InspectorBackendStub.highlightDOMNode = function(nodeId) {}
InspectorBackendStub.highlightFrame = function(frameId) {}
InspectorBackendStub.openInInspectedWindow = function(resourceURL) {}
InspectorBackendStub.pause = function() {}
InspectorBackendStub.performSearch = function(whitespaceTrimmedQuery, something) {}
InspectorBackendStub.populateScriptObjects = function(onPopulateScriptObjects) {}
InspectorBackendStub.pushNodeByPathToFrontend = function(path, didPushNodeByPathToFrontend) {}
InspectorBackendStub.pushNodeToFrontend = function(objectId, callback) {}
InspectorBackendStub.querySelectorAll = function(nodeId, selector, checkAffectsCallback) {}
InspectorBackendStub.registerDomainDispatcher = function(domainName, dispatcher) {}
InspectorBackendStub.releaseWrapperObjectGroup = function(id, watchObjectGroupId) {}
InspectorBackendStub.reloadPage = function(something) {}
InspectorBackendStub.removeAllScriptsToEvaluateOnLoad = function() {}
InspectorBackendStub.removeAttribute = function(nodeId, name, mycallback) {}
InspectorBackendStub.removeDOMBreakpoint = function(nodeId, type) {}
InspectorBackendStub.removeDOMStorageItem = function(id, key, callback) {}
InspectorBackendStub.removeEventListenerBreakpoint = function(eventName) {}
InspectorBackendStub.removeJavaScriptBreakpoint = function(breakpointId) {}
InspectorBackendStub.removeNode = function(nodeId, removeNodeCallback) {}
InspectorBackendStub.removeProfile = function(typeId, uid) {}
InspectorBackendStub.removeXHRBreakpoint = function(url) {}
InspectorBackendStub.resolveNode = function(nodeId, mycallback) {}
InspectorBackendStub.resourceContent = function(frameId, url, base64Encode, callbackWrapper) {}
InspectorBackendStub.resume = function() {}
InspectorBackendStub.searchCanceled = function() {}
InspectorBackendStub.setAllBrowserBreakpoints = function(stickyBreakpoints) {}
InspectorBackendStub.setConsoleMessagesEnabled = function(enabled) {}
InspectorBackendStub.setDOMBreakpoint = function(nodeId, type) {}
InspectorBackendStub.setDOMStorageItem = function(id, key, value, callback) {}
InspectorBackendStub.setEventListenerBreakpoint = function(eventName) {}
InspectorBackendStub.setExtraHeaders = function(allHeaders) {}
InspectorBackendStub.setJavaScriptBreakpoint = function(url, lineNumber, columnNumber, condition, enabled, didSetBreakpoint) {}
InspectorBackendStub.setJavaScriptBreakpointBySourceId = function(sourceID, lineNumber, columnNumber, condition, enabled, didSetBreakpoint) {}
InspectorBackendStub.setMonitoringXHREnabled = function(enabled) {}
InspectorBackendStub.setOuterHTML = function(nodeId, value, selectNode) {}
InspectorBackendStub.setPauseOnExceptionsState = function(pauseOnExceptionsState, callback) {}
InspectorBackendStub.setRuleSelector = function(ruleId, newSelector, callback) {}
InspectorBackendStub.setSearchingForNode = function(enabled, setSearchingForNode) {}
InspectorBackendStub.setStyleSheetText = function(id, newText, callback) {}
InspectorBackendStub.setUserAgentOverride = function(userAgent) {}
InspectorBackendStub.setXHRBreakpoint = function(url) {}
InspectorBackendStub.startProfiling = function() {}
InspectorBackendStub.startTimelineProfiler = function() {}
InspectorBackendStub.stepInto = function() {}
InspectorBackendStub.stepOut = function() {}
InspectorBackendStub.stepOver = function() {}
InspectorBackendStub.stopProfiling = function() {}
InspectorBackendStub.stopTimelineProfiler = function() {}
InspectorBackendStub.takeHeapSnapshot = function(detailed) {}
InspectorBackendStub.toggleProperty = function(id, index, disabled, callback) {}


var InspectorBackend = InspectorBackendStub;
