<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
Author 	  : Luis Majano
Date        : 5/25/2007
Description :
	Base Unit Test Component based on MXUnit.
	{ADD MORE DESCRIPTION HERE}
	
	This is a base test component for testing coldbox handlers. All you need
	to do is add the extends portions of your test cases to this base test
	and you will have a coldbox handler test.  The setup method will need
	to be changed in order to match your application path.

	MODIFY:
	1) instance.AppMapping : To point to your application relative from the root
	                         or via CF Mappings.
	2) instance.ConfigMapping : The expanded path location of your coldbox configuration file.

	OPTIONAL:
	3) Execute the on App start handler. You will need to fill out the name
	   of the Application Start Handler to be executed.

<cfscript>
people = querySim('
id , name , mail
1 | weed | weed@theflowerpot.not
2 | bill | bill@theflowerpot.not
3 | ben | ben@theflowerpot.not
');
</cfscript>

---------------------------------------------------------------------->
<cfcomponent name="BaseTestCase" 
			 extends="mxunit.framework.TestCase" 
			 output="false" 
			 hint="A base unit test case for doing ColdBox Testing">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cfscript>
		variables.instance = structnew();
		
		/* Internal Properties */
		instance.appMapping = "";
		instance.configMapping = "";
		instance.controller = 0;
		instance.coldboxAppKey = "cbController";
		
		/* Public Properties */
		this.persist_framework = true;
		this.loadColdbox = true;
		
		/* Prepare Mocking Factory */
		instance.mockFactory = createObject("component","coldbox.system.testing.MockFactory").init();
	</cfscript>

	<cffunction name="setup" hint="The setup method">
		<cfscript>
		var appRootPath = expandPath(instance.AppMapping);
		
		/* Verify App Root Path */
		if( right(appRootPath,1) neq "/" ){
			appRootPath = appRootPath & "/";
		}
		/* Load ColdBox? */
		if( this.loadColdbox ){
			/* Check on Scope Firsty */
			if( structKeyExists(application,getColdboxAppKey()) ){
				instance.controller = application[getColdboxAppKey()];
			}
			else{
				//Initialize ColdBox
				instance.controller = CreateObject("component", "coldbox.system.testing.TestController").init( appRootPath );
				/* Verify Persistence */
				if( this.persist_framework ){
					application[getColdboxAppKey()] = instance.controller;
				}
				/* Setup */
				instance.controller.getLoaderService().configLoader(instance.ConfigMapping,instance.AppMapping);
			}
			
			//Create Initial Event Context
			setupRequest();
			
			//Clean up Initial Event Context
			getRequestContext().clearCollection();
		}
		</cfscript>
	</cffunction>
	
	<cffunction name="tearDown" hint="The teardown" >
		<cfscript>
			structDelete(application,"cbController");
		</cfscript>
	</cffunction>

<!------------------------------------------- HELPERS ------------------------------------------->

	<!--- getMockFactory --->
	<cffunction name="getMockFactory" output="false" access="private" returntype="coldbox.system.testing.MockFactory" hint="Get the mocking factory">
		<cfreturn instance.mockFactory>
	</cffunction>

	<!--- Reset the persistence --->
	<cffunction name="reset" access="private" returntype="void" hint="Reset the persistence of the unit test coldbox app" output="false" >
		<cfset structDelete(application,"cbController")>
	</cffunction>
	
	<!--- get/Set Coldbox App Key --->
	<cffunction name="getcoldboxAppKey" access="public" output="false" returntype="string" hint="Get the coldboxAppKey">
		<cfreturn instance.coldboxAppKey/>
	</cffunction>
	<cffunction name="setcoldboxAppKey" access="public" output="false" returntype="void" hint="Override the coldboxAppKey">
		<cfargument name="coldboxAppKey" type="string" required="true"/>
		<cfset instance.coldboxAppKey = arguments.coldboxAppKey/>
	</cffunction>
	
	<!--- getter for AppMapping --->
	<cffunction name="getAppMapping" access="private" returntype="string" output="false" hint="Get the AppMapping">
		<cfreturn instance.AppMapping>
	</cffunction>
	
	<!--- setter for AppMapping --->
	<cffunction name="setAppMapping" access="private" output="false" returntype="void" hint="Set the AppMapping">
		<cfargument name="AppMapping" type="string" required="true"/>
		<cfset instance.AppMapping = arguments.AppMapping/>
	</cffunction>

	<!--- getter for ConfigMapping --->
	<cffunction name="getConfigMapping" access="private" returntype="string" output="false" hint="Get the ConfigMapping">
		<cfreturn instance.ConfigMapping>
	</cffunction>
	
	<!--- setter for ConfigMapping --->
	<cffunction name="setConfigMapping" access="private" output="false" returntype="void" hint="Set the ConfigMapping">
		<cfargument name="ConfigMapping" type="string" required="true"/>
		<cfset instance.ConfigMapping = arguments.ConfigMapping/>
	</cffunction>

	<!--- getter for controller --->
	<cffunction name="getcontroller" access="private" returntype="any" output="false" hint="Get a reference to the ColdBox controller">
		<cfif this.persist_framework>
			<cfset instance.controller = application.cbController>
		</cfif>
		<cfreturn instance.controller>
	</cffunction>

	<!--- Get current request context --->
	<cffunction name="getRequestContext" access="private" output="false" returntype="any" hint="Get the event object">
		<cfreturn getController().getRequestService().getContext() >
	</cffunction>

	<!--- Setup a request context --->
	<cffunction name="setupRequest" access="private" output="false" returntype="void" hint="Setup a request with FORM/URL data">
		<cfset getController().getRequestService().requestCapture() >
	</cffunction>

	<!--- prepare request, execute request and retrieve request --->
	<cffunction name="execute" access="private" output="false" returntype="any" hint="Executes a framework lifecycle">
		<cfargument name="eventhandler" required="true" type="string" hint="The event to execute">
		<cfargument name="private" required="false" type="boolean" default="false" hint="Call a private event or not">
		<cfscript>
			var handlerResults = "";
			var requestContext = "";
			
			//Setup the request Context with setup FORM/URL variables set in the unit test.
			setupRequest();
			
			//TEST EVENT EXECUTION
			handlerResults = getController().runEvent(event=eventhandler,private=arguments.private);
			
			//Return the correct event context.
			requestContext = getRequestContext();
			
			//If we have results save
			if ( isDefined("handlerResults") ){
				requestContext.setValue("cbox_handler_results", handlerResults);
			}
			
			return requestContext;
		</cfscript>
	</cffunction>
	
	<!--- Announce Interception --->
	<cffunction name="announceInterception" access="private" returntype="void" hint="Announce an interception to the system." output="false" >
		<cfargument name="state" 			required="true"  type="string" hint="The interception state to execute">
		<cfargument name="interceptData" 	required="false" type="struct" default="#structNew()#" hint="A data structure used to pass intercepted information.">
		<cfset getController().getInterceptorService().processState(argumentCollection=arguments)>
	</cffunction>

	<!--- Interceptor Facade --->
	<cffunction name="getInterceptor" access="private" output="false" returntype="any" hint="Get an interceptor">
		<!--- ************************************************************* --->
		<cfargument name="interceptorClass" required="true" type="string" hint="The qualified class of the itnerceptor to retrieve">
		<!--- ************************************************************* --->
		<cfscript>
			return getController().getInterceptorService().getInterceptor(arguments.interceptorClass);
		</cfscript>
	</cffunction>
	
	<!--- Get Model --->
	<cffunction name="getModel" access="private" returntype="any" hint="Create or retrieve model objects by convention" output="false" >
		<!--- ************************************************************* --->
		<cfargument name="name" 				required="true"  type="string" hint="The name of the model to retrieve">
		<cfargument name="useSetterInjection" 	required="false" type="boolean" default="false"	hint="Whether to use setter injection alongside the annotations property injection. cfproperty injection takes precedence.">
		<cfargument name="onDICompleteUDF" 		required="false" type="string"	default="onDIComplete" hint="After Dependencies are injected, this method will look for this UDF and call it if it exists. The default value is onDIComplete">
		<cfargument name="debugMode" 			required="false" type="boolean" default="false" hint="Debugging Mode or not">
		<!--- ************************************************************* --->
		<cfreturn getController().getPlugin("BeanFactory").getModel(argumentCollection=arguments)>
	</cffunction>

	<!--- Dump facade --->
	<cffunction name="dumpit" access="private" hint="Facade for cfmx dump" returntype="void">
		<cfargument name="var" required="yes" type="any">
		<cfargument name="isAbort" type="boolean" default="false" required="false" hint="Abort also"/>
		<cfdump var="#var#">
		<cfif arguments.isAbort><cfabort></cfif>
	</cffunction>
	<!--- Rethrow Facade --->
	<cffunction name="rethrowit" access="private" returntype="void" hint="Rethrow facade" output="false" >
		<cfargument name="throwObject" required="true" type="any" hint="The cfcatch object">
		<cfthrow object="#arguments.throwObject#">
	</cffunction>
	<!--- Abort Facade --->
	<cffunction name="abortit" access="private" hint="Facade for cfabort" returntype="void" output="false">
		<cfabort>
	</cffunction>
	
	<cfscript>
	/**
	* Accepts a specifically formatted chunk of text, and returns it as a query object.
	* v2 rewrite by Jamie Jackson
	*
	* @param queryData      Specifically format chunk of text to convert to a query. (Required)
	* @return Returns a query object.
	* @author Bert Dawson (bert@redbanner.com)
	* @version 2, December 18, 2007
	* 
	*/
	function querySim(queryData) {
	    var fieldsDelimiter="|";
	    var colnamesDelimiter=",";
	    var listOfColumns="";
	    var tmpQuery="";
	    var numLines="";
	    var cellValue="";
	    var cellValues="";
	    var colName="";
	    var lineDelimiter=chr(10) & chr(13);
	    var lineNum=0;
	    var colPosition=0;
	
	    // the first line is the column list, eg "column1,column2,column3"
	    listOfColumns = Trim(ListGetAt(queryData, 1, lineDelimiter));
	    
	    // create a temporary Query
	    tmpQuery = QueryNew(listOfColumns);
	
	    // the number of lines in the queryData
	    numLines = ListLen(queryData, lineDelimiter);
	    
	    // loop though the queryData starting at the second line
	    for(lineNum=2; lineNum LTE numLines; lineNum = lineNum + 1) {
	     cellValues = ListGetAt(queryData, lineNum, lineDelimiter);
	
	        if (ListLen(cellValues, fieldsDelimiter) IS ListLen(listOfColumns,",")) {
	            QueryAddRow(tmpQuery);
	            for (colPosition=1; colPosition LTE ListLen(listOfColumns); colPosition = colPosition + 1){
	                cellValue = Trim(ListGetAt(cellValues, colPosition, fieldsDelimiter));
	                colName = Trim(ListGetAt(listOfColumns,colPosition));
	                QuerySetCell(tmpQuery, colName, cellValue);
	            }
	        }
	    }
	    
	    return( tmpQuery );
	    
	}
	</cfscript>

</cfcomponent>