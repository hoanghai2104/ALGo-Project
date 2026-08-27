namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Integration.SyncEngine;
using Microsoft.Service.Item;
#pragma warning disable AL0897
using Microsoft.Service.Document;
#pragma warning restore AL0897
using Microsoft.Integration.Dataverse;
codeunit 50110 IntegrationTableMappingCRM
{
    // Subtype = Install;
    // ObsoleteState = Pending;
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
        ServiceOrderItemLineMapping(IntegrationTableMapping, IntegrationFieldMapping);
        CustomerAssetMapping(IntegrationTableMapping, IntegrationFieldMapping);
    end;

    // Service Order Mapping
    local procedure ServiceOrderMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationFieldMapping: Record "Integration Field Mapping")
    var
        CRMFSWorkOrder: Record "FS Work Order";
        ServiceHeader: Record "Service Header";
        ServiceOrderAllocationLbl: Label 'SRVORDER';

    begin
        if IntegrationTableMapping.Get(ServiceOrderAllocationLbl) then begin

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceHeader.FieldNo(TechnitianName), CRMFSWorkOrder.FieldNo(phma_Technicien), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceHeader.FieldNo(FunctionalLocationID), CRMFSWorkOrder.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceHeader.FieldNo("Ship-to Code"), CRMFSWorkOrder.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

            InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceHeader.FieldNo("Nom du Proprietaire"), CRMFSWorkOrder.FieldNo(msdyn_Instructions), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);

        end;
    end;

    // Service Order item line Mapping
#pragma warning disable AA0137
    local procedure ServiceOrderItemLineMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationFieldMapping: Record "Integration Field Mapping")
#pragma warning restore AA0137
    var
#pragma warning disable AA0137
        CRMFSWorkOrderIncident: Record "FS Work Order Incident";
        ServiceItemLine: Record "Service Item Line";
#pragma warning restore AA0137
        ServiceOrderAllocationLbl: Label 'SRVORDERITEMLINE';

    begin
        if IntegrationTableMapping.Get(ServiceOrderAllocationLbl) then begin

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceItemLine.FieldNo(FunctionalLocationID), CRMFSWorkOrderIncident.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceItemLine.FieldNo("Ship-to Code"), CRMFSWorkOrderIncident.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

        end;
    end;

#pragma warning disable AA0137
    local procedure CustomerAssetMapping(IntegrationTableMapping: Record "Integration Table Mapping"; IntegrationFieldMapping: Record "Integration Field Mapping")
#pragma warning restore AA0137
    var
#pragma warning disable AA0137
        CRMFSCustomerAsset: Record "FS Customer Asset";
        ServiceItem: Record "Service Item";
#pragma warning restore AA0137
        ServiceOrderAllocationLbl: Label 'SVCITEM-CUSTASSET';

    begin
        if IntegrationTableMapping.Get(ServiceOrderAllocationLbl) then begin

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceItem.FieldNo(FunctionalLocationID), CRMFSCustomerAsset.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceItem.FieldNo("Ship-to Code"), CRMFSCustomerAsset.FieldNo(msdyn_FunctionalLocation), IntegrationFieldMapping.Direction::Bidirectional, '', true, true);

        end;
    end;

#pragma warning disable AA0228
    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
#pragma warning restore AA0228
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, IntegrationTableMapping.Direction::Bidirectional, 'CRM');
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationTableFieldNo);
        IntegrationFieldMapping.SetRange("Field No.", TableFieldNo);
        IntegrationFieldMapping.DeleteAll();

        IntegrationFieldMapping.Reset();

        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
            ConstValue, ValidateField, ValidateIntegrationTableField);
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", 'OnAfterResetConfiguration', '', true, true)]
    local procedure HandleOnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin

        ServiceOrderMapping(IntegrationTableMapping, IntegrationFieldMapping);

    end;
    //in
}