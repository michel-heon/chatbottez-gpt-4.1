const fs = require('fs');
const path = require('path');

// Files to fix
const filesToFix = [
  'src/middleware/quotaUsage.ts',
  'src/services/subscriptionService.ts', 
  'src/utils/auditLogger.ts',
  'src/utils/auth.ts',
  'src/utils/logger.ts'
];

function fixFile(filePath) {
  console.log(`Fixing ${filePath}...`);
  
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Add import if not present
  if (!content.includes('getErrorMessage')) {
    // Find the last import statement
    const importRegex = /import.*from.*['"];?\n/g;
    const imports = content.match(importRegex);
    if (imports) {
      const lastImportIndex = content.lastIndexOf(imports[imports.length - 1]);
      const insertPosition = lastImportIndex + imports[imports.length - 1].length;
      content = content.slice(0, insertPosition) + 
                "import { getErrorMessage } from '../utils/errorHandler';\n" +
                content.slice(insertPosition);
    }
  }
  
  // Replace error.message with getErrorMessage(error)
  content = content.replace(/error\.message/g, 'getErrorMessage(error)');
  
  // Fix jwtError.message
  content = content.replace(/jwtError\.message/g, 'getErrorMessage(jwtError)');
  
  // Fix logger colorMap type issue
  content = content.replace(
    /const color = colorMap\[logEntry\.level\] \|\| '';/g,
    'const color = colorMap[logEntry.level as keyof typeof colorMap] || \'\';'
  );
  
  // Fix quotaCheck.reason type issue
  content = content.replace(
    /quotaCheck\.reason/g,
    'quotaCheck.reason || \'Quota exceeded\''
  );
  
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`Fixed ${filePath}`);
}

// Fix all files
filesToFix.forEach(fixFile);

console.log('All files fixed!');
