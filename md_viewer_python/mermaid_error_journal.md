# Mermaid Error Learning Journal

## Common Parse Errors & Solutions

### 1. **Quote Characters in Node Labels**

#### **Error Pattern:**
```
Parse error on line X: Expecting 'SQE', 'DOUBLECIRCLEEND', 'PE', '-)', 'STADIUMEND', 'SUBROUTINEEND', 'PIPE', 'CYLINDEREND', 'DIAMOND_STOP', 'TAGEND', 'TRAPEND', 'INVTRAPEND', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'STR'
```

#### **Root Cause:**
Double quotes `"` or single quotes `'` inside node labels confuse the Mermaid parser.

#### **Examples of Problematic Code:**
```mermaid
Start([User Asks "What is our policy?"])
UserQuery[User Question<br/>"How do returns work?"]
Response["Generated response with quotes"]
```

#### **Solutions:**
```mermaid
Start([User Asks: What is our policy?])           # Remove quotes
UserQuery[User Question<br/>How do returns work?] # Remove quotes
Response[Generated response with quotes]           # Remove quotes
```

#### **Alternative Solutions:**
```mermaid
Start([User Asks Question])                       # Simplify text
UserQuery[User Question<br/>Example: Returns]     # Use "Example:" instead
Response[Generated response text]                 # Rephrase without quotes
```

#### **When Fixed:**
- 2024-12-28: Fixed "What is our refund policy?" in system overview
- 2024-12-28: Fixed "How do returns work?" in query processing section

---

### 2. **Undefined Node References**

#### **Error Pattern:**
```
Node 'NodeName' is not defined
```

#### **Root Cause:**
Referencing a node in connections before defining it as a labeled node.

#### **Examples of Problematic Code:**
```mermaid
flowchart TD
    Start --> ProcessDocs  # ProcessDocs referenced but not defined
    ProcessDocs --> End[Finish]  # ProcessDocs defined here
```

#### **Solution:**
```mermaid
flowchart TD
    Start --> ProcessDocs[Process Documents]  # Define when first used
    ProcessDocs --> End[Finish]
```

#### **When Fixed:**
- 2024-12-28: Fixed ProcessDocs undefined reference in document loading flow

---

### 3. **Overly Long Class Definition Lines**

#### **Error Pattern:**
```
Parse error: Line too long or complex class definition
```

#### **Root Cause:**
Extremely long single-line class definitions can cause parser issues.

#### **Examples of Problematic Code:**
```mermaid
class Node1,Node2,Node3,Node4,Node5,Node6,Node7,Node8,Node9,Node10,Node11,Node12 decision
```

#### **Solution:**
```mermaid
class Node1,Node2,Node3,Node4 decision
class Node5,Node6,Node7,Node8 decision
class Node9,Node10,Node11,Node12 decision
```

#### **When Fixed:**
- 2024-12-28: Split long class definition lines in main flow diagram

---

### 4. **Special Characters in Node Text**

#### **Error Pattern:**
```
Parse error on line X: Unexpected character
```

#### **Root Cause:**
Certain special characters like parentheses `()`, brackets `[]`, or pipes `|` in node text can interfere with Mermaid syntax.

#### **Examples of Problematic Code:**
```mermaid
Node[process_query() function]     # Parentheses cause issues
Node[Array[0] access]              # Brackets cause issues
Node[Choice A | Choice B]          # Pipe character causes issues
```

#### **Solutions:**
```mermaid
Node[process_query function]       # Remove parentheses
Node[Array element access]         # Rephrase without brackets
Node[Choice A or Choice B]         # Use "or" instead of pipe
```

#### **When Fixed:**
- 2024-12-28: Removed parentheses from function names like "process_query()"

---

### 5. **Disconnected Flow Logic**

#### **Error Pattern:**
```
Warning: Unreachable nodes detected
```

#### **Root Cause:**
Nodes that don't connect to the main flow or have no path to end nodes.

#### **Examples of Problematic Code:**
```mermaid
flowchart TD
    Start --> Node1
    Node1 --> End

    OrphanNode[Disconnected]  # This node has no connections
    Node2 --> Node3           # These nodes don't connect to main flow
```

#### **Solution:**
```mermaid
flowchart TD
    Start --> Node1
    Node1 --> Node2           # Connect all nodes in logical sequence
    Node2 --> Node3
    Node3 --> End
```

#### **When Fixed:**
- 2024-12-28: Connected orphaned pipeline nodes in system overview

---

## Prevention Checklist

### ✅ **Before Committing Mermaid Code:**

1. **Text Content Check:**
   - [ ] Remove all double quotes `"` from node labels
   - [ ] Remove all single quotes `'` from node labels
   - [ ] Remove parentheses `()` from function names
   - [ ] Replace pipe `|` with "or" in choice text

2. **Node Definition Check:**
   - [ ] All referenced nodes are defined with labels
   - [ ] No orphaned/disconnected nodes
   - [ ] Clear flow from start to end nodes

3. **Syntax Check:**
   - [ ] Class definitions split across multiple lines if long
   - [ ] All connections use proper arrow syntax `-->`
   - [ ] Style definitions reference existing nodes

4. **Testing:**
   - [ ] Test in Mermaid Live Editor (https://mermaid.live)
   - [ ] Verify rendering in intended platform
   - [ ] Check on both light and dark themes if applicable

---

## Quick Fixes Reference

| **Problem** | **Quick Fix** | **Example** |
|---|---|---|
| Quotes in labels | Remove quotes | `"Text"` → `Text` |
| Function parentheses | Remove parentheses | `func()` → `func` |
| Undefined nodes | Define on first use | `A --> B` → `A --> B[Label]` |
| Long class lines | Split into multiple | `class A,B,C,D,E style` → `class A,B style; class C,D,E style` |
| Disconnected nodes | Connect to flow | Add proper arrows between nodes |
| Special characters | Replace with words | `A \| B` → `A or B` |

---

## Testing Workflow

### **1. Local Testing:**
```bash
# Copy mermaid code block content only (without ```mermaid tags)
# Paste into https://mermaid.live
# Verify rendering without errors
```

### **2. Common Test Cases:**
- Test with quotes: `"test"` and `'test'`
- Test with functions: `function()`
- Test with choices: `A | B`
- Test with long text: Very long node labels
- Test flow completeness: All nodes connected

### **3. Platform Testing:**
- GitHub markdown preview
- VS Code with Mermaid extension
- Documentation platforms (GitBook, etc.)

---

## Error Pattern Recognition

### **Quote-Related Errors:**
- Always mention `STR` in error message
- Usually occur on lines with quoted text
- Line number points to the problematic quote

### **Node-Related Errors:**
- Mention undefined node names
- Usually clear about which node is missing
- Easy to fix by adding proper node definition

### **Syntax Errors:**
- Mention unexpected characters or tokens
- Often point to specific line and character position
- May require examining surrounding syntax context

---

*Last Updated: 2024-12-28*
*Errors Catalogued: 5*
*Fixes Applied: 7*