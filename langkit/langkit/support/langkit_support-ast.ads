with System;

with Langkit_Support.Extensions; use Langkit_Support.Extensions;
with Langkit_Support.Tokens;     use Langkit_Support.Tokens;
with Langkit_Support.Token_Data_Handler;
use Langkit_Support.Token_Data_Handler;
with Langkit_Support.Vectors;

package Langkit_Support.AST is

   type AST_Node_Type is tagged;
   type AST_Node_Access is access all AST_Node_Type;
   type AST_Node is access all AST_Node_Type'Class;

   type Extension_Type is new System.Address;
   type Extension_Access is access all Extension_Type;

   type Extension_Destructor is
     access procedure (Node      : AST_Node;
                       Extension : Extension_Type)
     with Convention => C;
   --  Type for extension destructors. The parameter are the "node" the
   --  extension was attached to and the "extension" itself.

   type Extension_Slot is record
      ID        : Extension_ID;
      Extension : Extension_Access;
      Dtor      : Extension_Destructor;
   end record;

   package Extension_Vectors is new Langkit_Support.Vectors
     (Element_Type => Extension_Slot);

   type AST_Node_Type is abstract tagged record
      Parent                 : AST_Node := null;
      Token_Data             : Token_Data_Handler_Access := null;
      Token_Start, Token_End : Natural  := 0;
      Extensions             : Extension_Vectors.Vector;
   end record;

   type Child_Or_Trivia is (Child, Trivia);

   type Child_Record (Kind : Child_Or_Trivia := Child) is record
      case Kind is
         when Child =>
            Node : AST_Node;
         when Trivia =>
            Trivia : Token;
      end case;
   end record;

   package Children_Vectors is
     new Langkit_Support.Vectors (Child_Record);
   package Children_Arrays renames Children_Vectors.Elements_Arrays;

   package AST_Node_Vectors is new Langkit_Support.Vectors (AST_Node);
   package AST_Node_Arrays renames AST_Node_Vectors.Elements_Arrays;

   type Visit_Status is (Into, Over, Stop);
   type AST_Node_Kind is new Natural;

   function Kind (Node : access AST_Node_Type)
                  return AST_Node_Kind is abstract;
   function Kind_Name (Node : access AST_Node_Type) return String is abstract;
   function Image (Node : access AST_Node_Type) return String is abstract;

   function Child_Count (Node : access AST_Node_Type)
                         return Natural is abstract;
   procedure Get_Child (Node   : access AST_Node_Type;
                        Index  : Natural;
                        Exists : out Boolean;
                        Result : out AST_Node) is abstract;

   function Child (Node  : AST_Node;
                   Index : Natural) return AST_Node;

   function Children (Node : AST_Node) return AST_Node_Arrays.Array_Type;
   --  Return an array containing all the children of Node.
   --  This is an alternative to the Child/Child_Count pair, useful if you want
   --  the convenience of ada arrays, and you don't care about the small
   --  performance hit of creating an array.

   function Children_With_Trivia
     (Node : AST_Node) return Children_Arrays.Array_Type;
   --  Return the children of this node interleaved with Trivia token nodes, so
   --  that:
   --  - Every trivia contained between Node.Start_Token and Node.End_Token - 1
   --    will be part of the returned array
   --  - Nodes and trivias will be lexically ordered

   procedure PP_Trivia (Node : AST_Node; Level : Integer := 0);

   function Traverse
     (Node  : AST_Node;
      Visit : access function (Node : AST_Node) return Visit_Status)
     return Visit_Status;
   --  Given the parent node for a subtree, traverse all syntactic nodes of
   --  this tree, calling the given function on each node in pre order (ie.
   --  top-down). The order of traversing subtrees follows the order of
   --  declaration of the corresponding attributes in the grammar. The
   --  traversal is controlled as follows by the result returned by Visit:
   --
   --     Into   The traversal continues normally with the syntactic
   --            children of the node just processed.
   --
   --     Over   The children of the node just processed are skipped and
   --            excluded from the traversal, but otherwise processing
   --            continues elsewhere in the tree.
   --
   --     Stop   The entire traversal is immediately abandoned, and the
   --            original call to Traverse returns Stop.

   procedure Traverse
     (Node  : AST_Node;
      Visit : access function (Node : AST_Node) return Visit_Status);
   --  This is the same as Traverse function except that no result is returned
   --  i.e. the Traverse function is called and the result is simply discarded

   procedure Validate (Node   : access AST_Node_Type;
                       Parent : AST_Node := null) is abstract;
   --  Perform consistency checks on Node. Check that Parent is Node's parent.

   procedure Print (Node  : access AST_Node_Type;
                    Level : Natural := 0) is abstract;

   function Sloc_Range (Node : AST_Node;
                        Snap : Boolean := False) return Source_Location_Range;
   function Lookup (Node : AST_Node;
                    Sloc : Source_Location;
                    Snap : Boolean := False) return AST_Node;
   function Compare (Node : AST_Node;
                     Sloc : Source_Location;
                     Snap : Boolean := False) return Relative_Position;

   function Lookup_Children (Node : access AST_Node_Type;
                             Sloc : Source_Location;
                             Snap : Boolean := False) return AST_Node
                                is abstract;

   procedure Lookup_Relative (Node       : AST_Node;
                              Sloc       : Source_Location;
                              Position   : out Relative_Position;
                              Node_Found : out AST_Node;
                              Snap       : Boolean := False);

   function Get_Extension
     (Node : AST_Node;
      ID   : Extension_ID;
      Dtor : Extension_Destructor) return Extension_Access;
   --  Get (and create if needed) the extension corresponding to ID for Node.
   --  If the extension is created, the Dtor destructor is associated to it.
   --  Note that the returned access is not guaranteed to stay valid after
   --  subsequent calls to Get_Extension.

   procedure Free_Extensions (Node : access AST_Node_Type);

   procedure Destroy
     (Node : access AST_Node_Type) is abstract;

   function Is_Empty_List (Node : access AST_Node_Type) return Boolean is
     (False);

end Langkit_Support.AST;