component extends="preside.system.base.AdminHandler" {

	property name="widgetService" inject="adminDashboardWidgetService";
	property name="siteService"   inject="siteService";

	public void function renderWidgetContent( event, rc, prc ) {
		var widgetId         = rc.widgetId         ?: "";
		var dashboardId      = rc.dashboardId      ?: "";
		var instanceId       = rc.instanceId       ?: "";
		var configInstanceId = rc.configInstanceId ?: "";

		if ( !widgetService.userCanViewWidget( widgetId ) ) {
			event.adminAccessDenied();
		}

		event.renderData( type="html", data=widgetService.renderWidgetContent(
			  dashboardId      = dashboardId
			, widgetId         = widgetId
			, instanceId       = instanceId
			, configInstanceId = configInstanceId
			, requestData      = rc
		) );
	}

	public void function configModal( event, rc, prc ) {
		var widgetId    = rc.widgetId    ?: "";
		var dashboardId = rc.dashboardId ?: "";
		var instanceId  = rc.configInstanceId  ?: "";

		if ( !widgetService.userCanViewWidget( widgetId ) ) {
			event.adminAccessDenied();
		}
		if ( !widgetService.widgetHasConfigForm( widgetId ) ) {
			event.notFound();
		}

		prc.configForm = widgetService.renderWidgetConfigForm(
			  dashboardId = dashboardId
			, widgetId    = widgetId
			, instanceId  = instanceId
		);

		event.include( "/js/admin/specific/admindashboards/configmodal/" );

		event.setLayout( "adminModalDialog" );
	}

	public void function saveWidgetConfig( event, rc, prc ) {
		var widgetId    = rc.widgetId ?: "";
		var dashboardId = rc.dashboardId ?: "";
		var instanceId  = rc.configInstanceId ?: "";

		if ( !widgetService.userCanViewWidget( widgetId ) ) {
			event.adminAccessDenied();
		}
		if ( !widgetService.widgetHasConfigForm( widgetId ) ) {
			event.notFound();
		}

		widgetService.saveWidgetConfiguration(
			  dashboardId = dashboardId
			, widgetId    = widgetId
			, instanceId  = instanceId
			, requestData = event.getCollectionWithoutSystemVars()
		);

		event.renderData( data={ success=true }, type="json" );
	}

	private string function renderDashboard( event, rc, prc, args={} ) {
		var renderedWidgets = widgetService.renderDashboard( argumentCollection=args );

		event.include( "/js/admin/specific/admindashboards/" )
		     .include( "/css/admin/specific/admindashboards/" );

		return renderView( view="/admin/admindashboards/_dashboard", args={ widgets=renderedWidgets, dashboardId=args.dashboardId ?: "" } );
	}

	public void function widgetDialog( event, rc, prc ) {
		event.setLayout( "adminModalDialog" );
		prc.widgets = _getSortedAndTranslatedAdminWidgets();

		event.setView( view="admin/admindashboards/browserDialog", nolayout=true );
	}

	public function addWidget( event, rc, prc, args={} ) {
		var dashboardId = rc.dashboard ?: "";
		var widgetId    = rc.widget    ?: "";
		var instanceId  = createUUID();

		widgetService.addWidget(
			  dashboardId = dashboardId
			, widgetId    = widgetId
			, instanceId  = instanceId
			, title       = translateResource( uri="admin.admindashboards.widget.#widgetId#:title", defaultValue=widgetId )
			, config      = {}
		);

		setNextEvent( url=event.buildAdminLink( objectName="admin_dashboard", recordId=dashboardId ) );
	}

	public function deleteWidget( event, rc, prc, args={} ) {
		dashboardId = args.dashboardId ?: ( rc.dashboardId ?: "" );
		instanceId  = args.instanceId  ?: ( rc.instanceId  ?: "" );

		widgetService.deleteWidget(
			  dashboardId = dashboardId
			, instanceId  = instanceId
		);

		setNextEvent( url=event.buildAdminLink( objectName="admin_dashboard", recordId=dashboardId ) );
	}


// private helpers

	private query function _getSortedAndTranslatedAdminWidgets() {
		// todo, cache this operation (per locale)
		var unsortedOrTranslated         = widgetService.getWidgets();
		var tempArray                    = [];
		var activeSiteTemplate           = siteService.getActiveSiteTemplate();
		var isUserDashboardWidgetHandler = "";
		var isUserDashboardWidget        = false;

		for( var id in unsortedOrTranslated ) {
			var widget = Duplicate( unsortedOrTranslated[ id ] );

			if ( widget.siteTemplates == "*" || ListFindNoCase( widget.siteTemplates, activeSiteTemplate ) ) {
				if ( ! widgetService.isUserDashboardWidget( widget.id ) ) {
					continue;
				}

				widget.title       = translateResource( uri=widget.title      , defaultValue=widget.title );
				widget.description = translateResource( uri=widget.description, defaultValue="" );
				widget.icon        = translateResource( uri=widget.icon       , defaultValue="fa-magic" );

				tempArray.append( widget );
			}
		}

		tempArray.sort( function( widget1, widget2 ){
			return widget1.title == widget2.title ? 0 : ( widget1.title > widget2.title ? 1 : -1 );
		} );

		return arrayOfStructsToQuery( "id,title,description,icon", tempArray );
	}
}