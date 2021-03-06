with Ada.Exceptions;                  use Ada.Exceptions;
with Ada.Strings.Wide_Wide_Unbounded; use Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;

with GNATCOLL.Projects; use GNATCOLL.Projects;
with GNATCOLL.VFS;      use GNATCOLL.VFS;

with Langkit_Support.Diagnostics; use Langkit_Support.Diagnostics;
with Langkit_Support.Text;        use Langkit_Support.Text;

with Libadalang.Analysis;            use Libadalang.Analysis;
with Libadalang.Unit_Files;          use Libadalang.Unit_Files;
with Libadalang.Unit_Files.Projects; use Libadalang.Unit_Files.Projects;

procedure Main is

   function Load_Project (File : String) return Unit_Provider_Access;

   function "+" (S : Wide_Wide_String) return Unbounded_Wide_Wide_String
      renames To_Unbounded_Wide_Wide_String;
   function "+" (S : Unbounded_Wide_Wide_String) return Wide_Wide_String
      renames To_Wide_Wide_String;

   ------------------
   -- Load_Project --
   ------------------

   function Load_Project (File : String) return Unit_Provider_Access is
      Env     : Project_Environment_Access;
      Project : constant Project_Tree_Access := new Project_Tree;
   begin
      Initialize (Env);
      Load (Project.all, Create (+File), Env);
      return new Project_Unit_Provider_Type'(Create (Project, Env, True));
   end Load_Project;

   UFP : Unit_Provider_Access := Load_Project ("p.gpr");
   Ctx  : Analysis_Context :=
      Create (Unit_Provider => Unit_Provider_Access_Cst (UFP));
   Unit : Analysis_Unit;

   LF    : constant := Character'Pos (ASCII.LF);
   Space : constant := Character'Pos (' ');

   Filenames : array (Positive range <>) of Unbounded_Wide_Wide_String :=
     (+(1 => Wide_Wide_Character'Val (LF)),
      +"unknown_unit");

begin
   for File of Filenames loop
      Put_Line ("Trying to get unit: " & Image (+File, With_Quotes => True));
      begin
         Unit := Get_From_Provider (Ctx, +File, Unit_Specification);

         Put_Line ("   ...   got no exception.");
         if Has_Diagnostics (Unit) then
            Put_Line ("   ...   but we got diagnostics:");
            for D of Diagnostics (Unit) loop
               Put_Line ("   " & To_Pretty_String (D));
            end loop;
         end iF;
      exception
         when Exc : Invalid_Unit_Name_Error =>
            Put_Line ("   ... got an exception:");
            Put_Line ("   " & Exception_Name (Exc));
            Put_Line ("   " & Exception_Message (Exc));
      end;
   end loop;

   Destroy (Ctx);
   Destroy (UFP);
   Put_Line ("Done.");
end Main;
