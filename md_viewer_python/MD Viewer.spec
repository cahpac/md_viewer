# -*- mode: python ; coding: utf-8 -*-

a = Analysis(
    ['md_viewer.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('puppeteer-config.json', '.'),
        ('resources/js/mermaid.min.js', 'js'),
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='MD Viewer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='MD Viewer',
)
app = BUNDLE(
    coll,
    name='MD Viewer.app',
    icon=None,
    bundle_identifier='com.cahpac.mdviewer',
    info_plist={
        'CFBundleShortVersionString': '2.1.0+20251019.git1a6d5eb.macos-arm64',
        'CFBundleVersion': '2.1.0+20251019.git1a6d5eb.macos-arm64',
        'NSHighResolutionCapable': True,
        'CFBundleDocumentTypes': [
            {
                'CFBundleTypeName': 'Markdown Document',
                'CFBundleTypeRole': 'Viewer',
                'CFBundleTypeExtensions': ['md', 'markdown', 'mdown', 'mkd'],
                'CFBundleTypeIconFile': '',
                'LSHandlerRank': 'Owner',
            }
        ],
    },
)
