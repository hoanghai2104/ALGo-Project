codeunit 50105 DataverseIntegration
{
    Description = 'For CDS tables mapping';
    trigger OnRun()
    begin
        installMapping();
    end;

    procedure installMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationEnabled: Boolean;
    begin

        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if not CDSIntegrationEnabled then
            exit;

        ServiceOrderMapping(IntegrationTableMapping, IntegrationFieldMapping);
    end;

    local procedure ServiceOrderMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationFieldMapping: Record "Integration Field Mapping")
    var
        CDSFunctionalLocation: Record "CDS msdyn_FunctionalLocation";
        ShipToAddress: Record "Ship-to Address";

    begin
        if IntegrationTableMapping.Get(ShipToAdressLbl) then begin
            InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Customer No."), CDSFunctionalLocation.FieldNo(phma_Compte), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", OnGetCDSTableNo, '', false, false)]
    local procedure "CRM Setup Defaults_OnGetCDSTableNo"(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    begin
        if BCTableNo = Database::"Ship-to Address" then begin
            CDSTableNo := Database::"CDS msdyn_FunctionalLocation";
            handled := true;
        end;
    end;


    //used as integration table in page
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lookup CRM Tables", OnLookupCRMTables, '', true, true)]
    local procedure HandleOnLookupCRMTables(CRMTableID: Integer; NAVTableId: Integer; SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text; var Handled: Boolean)
    begin
        if CRMTableID = Database::"CDS msdyn_FunctionalLocation" then
            Handled := this.LookupCDSFunctionalLocation(SavedCRMId, CRMId, IntTableFilter);
    end;

    local procedure LookupCDSFunctionalLocation(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CDS_msdyn_FunctionalLocation: Record "CDS msdyn_FunctionalLocation";
        OriginalCDS_msdyn_FunctionalLocation: Record "CDS msdyn_FunctionalLocation";
        // OriginalCDS_msdyn_FunctionalLocationList: Page "Ship-to Address List";
        OriginalCDS_msdyn_FunctionalLocationList: Page CrmShipToAddress;
    begin
        if not IsNullGuid(CRMId) then begin
            if CDS_msdyn_FunctionalLocation.Get(CRMId) then
                OriginalCDS_msdyn_FunctionalLocationList.SetRecord(CDS_msdyn_FunctionalLocation);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCDS_msdyn_FunctionalLocation.Get(SavedCRMId) then
                    OriginalCDS_msdyn_FunctionalLocationList.SetCurrentlyCoupledShipToAddress(OriginalCDS_msdyn_FunctionalLocation);
        end;

        CDS_msdyn_FunctionalLocation.SetView(IntTableFilter);
        OriginalCDS_msdyn_FunctionalLocationList.SetTableView(CDS_msdyn_FunctionalLocation);
        OriginalCDS_msdyn_FunctionalLocationList.LookupMode(true);
        if OriginalCDS_msdyn_FunctionalLocationList.RunModal() = ACTION::LookupOK then begin
            OriginalCDS_msdyn_FunctionalLocationList.GetRecord(CDS_msdyn_FunctionalLocation);
            CRMId := CDS_msdyn_FunctionalLocation.msdyn_FunctionalLocationId;
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", OnAddEntityTableMapping, '', false, false)]
    local procedure "CRM Setup Defaults_OnAddEntityTableMapping"(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        this.AddEntityTableMapping(ShipToAdressLbl, DATABASE::"CDS msdyn_FunctionalLocation", TempNameValueBuffer);
    end;


    local procedure AddEntityTableMapping(CRMEntityTypeName: Text; TableID: Integer; var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := TempNameValueBuffer.Count + 1;
        TempNameValueBuffer.Name := CopyStr(CRMEntityTypeName, 1, MaxStrLen(TempNameValueBuffer.Name));
        TempNameValueBuffer.Value := Format(TableID);
        if TempNameValueBuffer.Insert() then;
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, IntegrationTableMapping.Direction::Bidirectional, 'CDS');
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationTableFieldNo);
        if IntegrationFieldMapping.IsEmpty then
            IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
                ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", 'OnAfterResetConfiguration', '', true, true)]
    local procedure HandleOnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSFunctionalLocation: Record "CDS msdyn_FunctionalLocation";
        ShipToAddress: Record "Ship-to Address";
    begin
        this.InsertIntegrationTableMapping(
            IntegrationTableMapping, ShipToAdressLbl,
            DATABASE::"Ship-to Address", DATABASE::"CDS msdyn_FunctionalLocation", CDSFunctionalLocation.FieldNo(msdyn_FunctionalLocationId), CDSFunctionalLocation.FieldNo(ModifiedOn), '', '', true);

        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Code), CDSFunctionalLocation.FieldNo(phma_BusinessCentralCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Name), CDSFunctionalLocation.FieldNo(msdyn_Name), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Address), CDSFunctionalLocation.FieldNo(msdyn_Address1), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Address 2"), CDSFunctionalLocation.FieldNo(msdyn_Address2), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Country/Region Code"), CDSFunctionalLocation.FieldNo(msdyn_Country), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Dataverse_City), CDSFunctionalLocation.FieldNo(msdyn_City), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Dataverse_PostCode), CDSFunctionalLocation.FieldNo(msdyn_PostalCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Customer No."), CDSFunctionalLocation.FieldNo(phma_Compte), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
    end;
    //in
    var
        ShipToAdressLbl: Label 'SHIP TO ADDRESS';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lookup CRM Tables", OnLookupCRMOption, '', false, false)]
    local procedure "Lookup CRM Tables_OnLookupCRMOption"(CRMTableID: Integer; NAVTableId: Integer; SavedCRMOptionId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]; IntTableFilter: Text; var Handled: Boolean)
    begin
    end;

}