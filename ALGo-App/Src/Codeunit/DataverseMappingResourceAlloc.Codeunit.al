namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Integration.SyncEngine;
using Microsoft.Service.Document;
#pragma warning disable AL0897
using Microsoft.Integration.Dataverse;
#pragma warning restore AL0897
codeunit 50107 DataverseMappingResourceAlloc
{
    // Subtype = Install;
    ObsoleteState = Pending;
    ObsoleteReason = 'to be removed';
    trigger OnRun()
    begin
        installMapping();
    end;

    procedure installMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMFSBookableResourceBooking: Record "FS Bookable Resource Booking";
        ServiceOrderAllocation: Record "Service Order Allocation";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ServiceOrderAllocationLbl: Label 'ServOdrAllocation';
        CDSIntegrationEnabled: Boolean;


    begin


        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if not CDSIntegrationEnabled then
            exit;

        if not IntegrationTableMapping.Get(ServiceOrderAllocationLbl) then begin
            this.InsertIntegrationTableMapping(
               IntegrationTableMapping, ServiceOrderAllocationLbl,
               DATABASE::"Service Order Allocation", DATABASE::"FS Bookable Resource Booking", CRMFSBookableResourceBooking.FieldNo(BookableResourceBookingId), CRMFSBookableResourceBooking.FieldNo(ModifiedOn), '', '', false);
            // InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceOrderAllocation.FieldNo("Resource No."), CRMFSBookableResourceBooking.FieldNo(Resource), IntegrationFieldMapping.Direction::FromIntegrationTable, '', true, false);
            InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceOrderAllocation.FieldNo("Document No."), CRMFSBookableResourceBooking.FieldNo(Name), IntegrationFieldMapping.Direction::FromIntegrationTable, '', true, false);
            InsertIntegrationFieldMapping(ServiceOrderAllocationLbl, ServiceOrderAllocation.FieldNo("Document Type"), 0, IntegrationFieldMapping.Direction::FromIntegrationTable, 'Order', true, false);
        end else begin

        end;
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, IntegrationTableMapping.Direction::Bidirectional, 'CRM');
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
            ConstValue, ValidateField, ValidateIntegrationTableField);
    end;



    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", 'OnAfterResetConfiguration', '', true, true)]
    // local procedure HandleOnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    // var
    //     IntegrationTableMapping: Record "Integration Table Mapping";
    //     IntegrationFieldMapping: Record "Integration Field Mapping";
    //     CRMFSBookableResourceBooking: Record "FS Bookable Resource Booking";
    //     ServiceOrderAllocation: Record "Service Order Allocation";
    //     ServiceOrderAllocationLbl: Label 'ServOdrAllocation';
    //     CDSIntegrationEnabled: Boolean;
    //     CRMIntegrationManagement: Codeunit "CRM Integration Management";
    // begin
    //     this.InsertIntegrationTableMapping(
    //           IntegrationTableMapping, ServiceOrderAllocationLbl,
    //           DATABASE::"Service Order Allocation", DATABASE::"FS Bookable Resource Booking", CRMFSBookableResourceBooking.FieldNo(BookableResourceBookingId), CRMFSBookableResourceBooking.FieldNo(ModifiedOn), '', '', true);
    // end;
    //in
}