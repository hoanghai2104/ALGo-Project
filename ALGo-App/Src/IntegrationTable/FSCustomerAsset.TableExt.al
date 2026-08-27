namespace Marechal.DataverseMapping;
using Microsoft.Integration.DynamicsFieldService;
tableextension 50203 FSCustomerAsset extends "FS Customer Asset"
{
    fields
    {
        // Add changes to table fields here
        field(50100; phma_Nserie; Text[100])
        {
            ExternalName = 'phma_nserie';
            ExternalType = 'String';
            Description = '';
            Caption = 'N° série';
        }
        field(50101; msdyn_FunctionalLocation; GUID)
        {
            ExternalName = 'msdyn_functionallocation';
            ExternalType = 'Lookup';
            Description = 'Poste technique de l’ordre de travail';
            Caption = 'Poste technique';
            TableRelation = "CDS msdyn_FunctionalLocation".msdyn_FunctionalLocationId;
        }
        field(50105; phma_Dateinstallation; Date)
        {
            ExternalName = 'phma_dateinstallation';
            ExternalType = 'DateTime';
            Description = '';
            Caption = 'Date installation';
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