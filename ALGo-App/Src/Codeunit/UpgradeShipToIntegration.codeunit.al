codeunit 50108 UpgradeShipToIntegration
{
    Subtype = upgrade;
    trigger OnUpgradePerCompany()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSFunctionalLocation: Record "CDS msdyn_FunctionalLocation";
        ShipToAddress: Record "Ship-to Address";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationEnabled: Boolean;
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if not CDSIntegrationEnabled then
            exit;


        if not IntegrationTableMapping.Get(ShipToAdressLbl) then
            exit;

        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Code), CDSFunctionalLocation.FieldNo(phma_BusinessCentralCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Name), CDSFunctionalLocation.FieldNo(msdyn_Name), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Address), CDSFunctionalLocation.FieldNo(msdyn_Address1), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Address 2"), CDSFunctionalLocation.FieldNo(msdyn_Address2), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Country/Region Code"), CDSFunctionalLocation.FieldNo(msdyn_Country), IntegrationFieldMapping.Direction::Bidirectional, 'Suisse', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Dataverse_City), CDSFunctionalLocation.FieldNo(msdyn_City), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Dataverse_PostCode), CDSFunctionalLocation.FieldNo(msdyn_PostalCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Customer No."), CDSFunctionalLocation.FieldNo(phma_Compte), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Code), CDSFunctionalLocation.FieldNo(msdyn_Name), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("E-Mail"), CDSFunctionalLocation.FieldNo(msdyn_EmailAddress), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Phone No."), CDSFunctionalLocation.FieldNo(msdyn_ShortName), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(Name), CDSFunctionalLocation.FieldNo(msdyn_AddressName), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Dataverse_Country/Region Code"), 0, IntegrationFieldMapping.Direction::FromIntegrationTable, 'CH', true, false);
        // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(msdyn_FunctionalLocationId), CDSFunctionalLocation.FieldNo(msdyn_FunctionalLocationId), IntegrationFieldMapping.Direction::Bidirectional, '1', true, false);

       // InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo(City), CDSFunctionalLocation.FieldNo(msdyn_City), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        //InsertIntegrationFieldMapping(ShipToAdressLbl, ShipToAddress.FieldNo("Post Code"), CDSFunctionalLocation.FieldNo(msdyn_PostalCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
    end;


    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Field No.", IntegrationTableFieldNo);
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationTableFieldNo);
        if IntegrationFieldMapping.IsEmpty then
            IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
                ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    var
        ShipToAdressLbl: Label 'SHIP TO ADDRESS';
}
