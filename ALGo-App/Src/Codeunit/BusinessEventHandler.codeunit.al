codeunit 50114 BusinessEventHandler
{
    //service order external event
    [ExternalBusinessEvent('ServiceOrderShipToCodeOnvalidate', 'Ship-to-Code on validate', 'Trigger when ship_to code has been validated', eventcategory::"Service Order")]
    procedure OnServiceOrderShipToModified(ServiceOrderId: Guid)
    begin
    end;

    [ExternalBusinessEvent('ServiceOrderModified', 'Service Order Modified', 'Trigger when Field has been validated', eventcategory::"Service Order")]
    procedure OnServiceOrderModified(ServiceOrderId: Guid)
    begin
    end;

    [ExternalBusinessEvent('ServiceOrderInserted', 'Service Order Inserted', 'Trigger when record has been inserted', eventcategory::"Service Order")]
    procedure OnServiceOrderInserted(ServiceOrderId: Guid)
    begin
    end;

    //fields
    [EventSubscriber(ObjectType::Table, Database::"Service Header", OnAfterValidateEvent, "Ship-to Code", false, false)]
    local procedure ServiceHeaderOnAfterModifyEventShipTo(var Rec: Record "Service Header")
    begin
        OnServiceOrderShipToModified(Rec.SystemId);
        OnServiceOrderModified(Rec.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", OnAfterValidateEvent, TechnitianName, false, false)]
    local procedure ServiceHeaderOnAfterModifyEventTechnitian(var Rec: Record "Service Header")
    begin
        OnServiceOrderModified(Rec.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", OnAfterValidateEvent, "Coupled to FS", false, false)]
    local procedure ServiceHeaderOnAfterModifyEventCoupledToFS(var Rec: Record "Service Header")
    begin
        OnServiceOrderModified(Rec.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", OnAfterInsertEvent, '', false, false)]
    local procedure ServiceHeaderOnAfterInsertEvent(var Rec: Record "Service Header")
    begin
        if IsNullGuid(Rec.SystemId) then
            exit;
        OnServiceOrderInserted(Rec.SystemId);
    end;


    //Service Item Line external event
    [ExternalBusinessEvent('ServiceItemLineModified', 'Service Item Line Modified', 'Trigger when Field has been validated', eventcategory::"Service Order")]
    procedure OnServiceItemLineModified(ServiceItemLineId: Guid)
    begin
    end;

    [ExternalBusinessEvent('ServiceItemLineInserted', 'Service Item Line Inserted', 'Trigger when record has been inserted', eventcategory::"Service Order")]
    procedure OnServiceItemLineInserted(ServiceItemLineId: Guid)
    begin
    end;

    //fields
    [EventSubscriber(ObjectType::Table, Database::"Service Item Line", OnAfterValidateEvent, "Ship-to Code", false, false)]
    local procedure ServiceItemLineOnAfterModifyEventShipTo(var Rec: Record "Service Item Line")
    begin
        OnServiceItemLineModified(Rec.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Line", OnAfterInsertEvent, '', false, false)]
    local procedure ServiceItemLineOnAfterInsertEvent(var Rec: Record "Service Item Line")
    begin
        if IsNullGuid(Rec.SystemId) then
            exit;
        OnServiceItemLineInserted(Rec.SystemId);
    end;

    //Service Item external event
    [ExternalBusinessEvent('ServiceItemModified', 'Service Item Modified', 'Trigger when Field has been validated', eventcategory::"Service Order")]
    procedure OnServiceItemModified(ServiceItemId: Guid)
    begin
    end;

    [ExternalBusinessEvent('ServiceItemInserted', 'Service Item Inserted', 'Trigger when record has been inserted', eventcategory::"Service Order")]
    procedure OnServiceItemInserted(ServiceItemId: Guid)
    begin
    end;

    //fields
    [EventSubscriber(ObjectType::Table, Database::"Service Item", OnAfterValidateEvent, "Ship-to Code", false, false)]
    local procedure ServiceItemOnAfterModifyEventShipTo(var Rec: Record "Service Item")
    begin
        OnServiceItemModified(Rec.SystemId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", OnAfterInsertEvent, '', false, false)]
    local procedure ServiceItemOnAfterInsertEvent(var Rec: Record "Service Item")
    begin
        if IsNullGuid(Rec.SystemId) then
            exit;
        // if Rec."Ship-to Code" = '' then
        //     exit; // remove filtering
        OnServiceItemInserted(Rec.SystemId);
    end;

    [ExternalBusinessEvent('ServiceItemAfterModified', 'Service Item After Modified', 'Trigger after when record has been modified', eventcategory::"Service Order")]
    procedure OnServiceItemAfterModified(ServiceItemId: Guid)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", OnAfterModifyEvent, '', false, false)]
    local procedure ServiceItemOnAfterModifyEvent(var Rec: Record "Service Item"; xRec: Record "Service Item")
    begin
        if Rec."Ship-to Code" = '' then
            exit;

        if Rec."Ship-to Code" <> xRec."Ship-to Code" then
            OnServiceItemAfterModified(Rec.SystemId);
    end;


    //Ship-to Address external event
    [ExternalBusinessEvent('ShipToAddressAfterInserted', 'Ship-to Address After Inserted', 'Trigger After insert and is coupled to Dataverse', eventcategory::"Service Order")]
    procedure OnShipToAddressAfterInsert(ShipToAddressId: Guid; msdyn_FunctionalLocationId: Guid)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", OnAfterInsertEvent, '', false, false)]
    local procedure ShipToAddressOnAfterInsertEvent(var Rec: Record "Ship-to Address")
    begin
        if IsNullGuid(Rec.SystemId) then
            exit;
        // Rec.CalcFields("Coupled to Dataverse");
        // if not (Rec."Coupled to Dataverse") then
        //     exit;

        if IsNullGuid(Rec.msdyn_FunctionalLocationId) then
            exit;

        OnShipToAddressAfterInsert(Rec.SystemId, Rec.msdyn_FunctionalLocationId);
    end;


}