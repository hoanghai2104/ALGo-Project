namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
using Microsoft.Sales.Customer;
tableextension 50202 FSWorkOrderintegration extends "FS Work Order"
{
    fields
    {
        // Add changes to table fields here
        field(50100; phma_Technicien; GUID)
        {
            ExternalName = 'phma_technicien';
            ExternalType = 'Lookup';
            Description = '';
            Caption = 'Technicien';
            TableRelation = "FS Bookable Resource".BookableResourceId;
            DataClassification = SystemMetadata;
        }
        field(50101; msdyn_FunctionalLocation; GUID)
        {
            ExternalName = 'msdyn_functionallocation';
            ExternalType = 'Lookup';
            Description = 'Poste technique de l''ordre de travail';
            Caption = 'Poste technique';
            TableRelation = "CDS msdyn_FunctionalLocation".msdyn_FunctionalLocationId;
            DataClassification = SystemMetadata;
            // trigger OnValidate()
            // var
            //     shiptoAddressRec: Record "Ship-to Address";
            // begin
            //     if not IsNullGuid(msdyn_FunctionalLocation) then
            //         shiptoAddressRec.SetCurrentKey("msdyn_FunctionalLocationId");
            //     shiptoAddressRec.SetRange("msdyn_FunctionalLocationId", msdyn_FunctionalLocation);

            // end;

        }
        field(50102; msdyn_Instructions; BLOB)
        {
            ExternalName = 'msdyn_instructions';
            ExternalType = 'Memo';
            Description = 'Affiche les instructions pour les ressources réservées. Par défaut, ces informations sont extraites du champ des instructions de l''ordre de travail du compte de service.';
            Caption = 'Instructions';
            Subtype = Memo;
        }
        field(50103; phma_Numerodebon; Text[100])
        {
            ExternalName = 'phma_numerodebon';
            ExternalType = 'String';
            Description = '';
            Caption = 'Numéro de bon';
        }
        field(50104; ToInvoice; Boolean)
        {
            ExternalName = 'phma_toinvoice';
            ExternalType = 'Boolean';
            Caption = 'To Invoice';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    //in
}