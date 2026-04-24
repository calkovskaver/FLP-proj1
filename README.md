### Problémy 
1. Práce s Mapou v Report.sh. Pro mě trochu komplikované na představení si její struktury a obsahu. Nicméně po vypsání obsahu mapy v testech už to nebylo tak abstraktní. 

2. RunDiffOnOutput v Execuor.sh - Tuto funkci jsem implementovala až po `checkInterpreterResult`, kde jsem ji mohla použít - čili v `checkInterpreterResult` je v podstatě také implementovaná. 

### Dokumentace kódu je přítomna vždy u implementovaných funkcí

### Další knihovny a specifické výrazy
1. Discovery.hs:
- `import System.Directory (doesDirectoryExist)` - pro kontrolu rekurzivního průchodu adresáře s testy
- `import Control.Monad (forM)` - pro monadický "průchod" cestami souborů, které jsou v zadaném adresáři

2. Executor.hs:
- `import Data.Maybe (isJust)` - ke kontrole hodnoty mOutFile. Pokud se jedná o Nothing, neproběhne kontrola.
- `import System.Directory (executable, getPermissions)` - Pro kontrolu oprávnění souboru, zda je executable, aby mohl být později spuštěn - např interpret nebo parser.

3. Parser.hs:
- `import Data.Char (isDigit)` - ke kontrole, zda se za parametry testu nachází jen a pouze platné celé číslo

4. Report.hs:
- `import Data.List (find)` - pro hledání definice testu s daným jménem, aby mohl být vytvořen odpovídající report podle kategorií