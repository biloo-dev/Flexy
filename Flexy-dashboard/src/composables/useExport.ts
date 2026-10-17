export function useExport() {
  const exportToCSV = (filename: string, rows: Record<string, any>[], headers?: { key: string; label: string }[]) => {
    if (!rows || !rows.length) {
      console.warn('No data available for export');
      return;
    }

    const columnKeys = headers ? headers.map(h => h.key) : Object.keys(rows[0]);
    const columnLabels = headers ? headers.map(h => `"${h.label.replace(/"/g, '""')}"`) : columnKeys.map(k => `"${k}"`);

    const csvContent = [
      columnLabels.join(','),
      ...rows.map(row =>
        columnKeys
          .map(key => {
            let val = row[key];
            if (val === null || val === undefined) {
              return '""';
            }
            if (typeof val === 'object') {
              val = JSON.stringify(val);
            }
            const stringVal = String(val).replace(/"/g, '""');
            return `"${stringVal}"`;
          })
          .join(',')
      )
    ].join('\r\n');

    const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `${filename}_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return {
    exportToCSV,
  };
}
