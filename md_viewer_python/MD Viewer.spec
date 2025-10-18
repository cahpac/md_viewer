# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['md_viewer.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('puppeteer-config.json', '.'),
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
    a.binaries,
    a.datas,
    [],
    name='MD Viewer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
app = BUNDLE(
    exe,
    name='MD Viewer.app',
    icon=None,
    bundle_identifier='com.cahpac.mdviewer',
    info_plist={
        'CFBundleShortVersionString': '2.0.0',
        'CFBundleVersion': '2.0.0',
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
