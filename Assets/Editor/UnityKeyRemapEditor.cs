using UnityEditor;
using UnityEngine;
using System.Text.RegularExpressions;
using System.Reflection;

//https://qiita.com/fujimisakari/items/36284ececdb06e3cdb4c

public class UnityKeyRemapEditor : EditorWindow
{
	// オブジェクトの共通Openコマンド
	[MenuItem("KeyRemap/Open &o")]
	static void KeyRemapOpen()
	{
		foreach (var aObj in Selection.objects)
		{
			var aObjPath = AssetDatabase.GetAssetPath(aObj);
			if (Regex.IsMatch(aObjPath, @"^.*\.unity"))  { EditorApplication.OpenScene(aObjPath); }
			if (Regex.IsMatch(aObjPath, @"^.*\.cs"))     { AssetDatabase.OpenAsset(aObj); }
			if (Regex.IsMatch(aObjPath, @"^.*\.prefab"))
			{
				PrefabUtility.InstantiatePrefab(aObj);
				CommonExecuteMenuItem("Window/Hierarchy");
			}
		}
	}

	// ゲームオブジェクト作成
	[MenuItem("KeyRemap/CreateGameObject &g")]
	static void KeyRemapCreateGameObject() { CommonExecuteMenuItem("GameObject/Create Empty"); }

	// ゲームオブジェクトの削除
	[MenuItem("KeyRemap/Delete &h")]
	static void KeyRemapDelete()
	{
		foreach (var aObj in Selection.objects)
		{
			GameObject aGameObject = aObj as GameObject;
			if (aGameObject) { GameObject.DestroyImmediate(aGameObject); }
		}
	}

	// ゲームオブジェクトの有効、無効
	[MenuItem("KeyRemap/ActiveToggle &t")]
	static void KeyRemapActiveToggle()
	{
		foreach (var aObj in Selection.objects)
		{
			GameObject aGameObject = aObj as GameObject;
			if (aGameObject) { aGameObject.SetActive(!aGameObject.activeSelf); }
		}
	}

	// PrefabのApply
	[MenuItem("KeyRemap/PrefabApply &a")]
	static void KeyRemapPrefabApply() { CommonExecuteMenuItem("GameObject/Apply Changes To Prefab"); }

	// コンソール出力のクリア
	[MenuItem("KeyRemap/ClearConsoleLogs &c")]
	private static void ClearConsoleLogs()
	{
		var assembly = Assembly.GetAssembly(typeof(SceneView));
		var type = assembly.GetType("UnityEditor.LogEntries");
		var method = type.GetMethod("Clear");
		method.Invoke(new object(), null);
	}

	// 再インポート
	[MenuItem("KeyRemap/Reimport &r")]
	static void KeyRemapReimport() { CommonExecuteMenuItem("Assets/Reimport"); }

	// フォーカス変更
	[MenuItem("KeyRemap/Scene #&s")]
	static void KeyRemapScene() { CommonExecuteMenuItem("Window/Scene"); }

	[MenuItem("KeyRemap/Scene #&g")]
	static void KeyRemapGame() { CommonExecuteMenuItem("Window/Game"); }

	[MenuItem("KeyRemap/Inspector #&i")]
	static void KeyRemapInspector() { CommonExecuteMenuItem("Window/Inspector"); }

	[MenuItem("KeyRemap/Hierarchy #&h")]
	static void KeyRemapHierarchy() { CommonExecuteMenuItem("Window/Hierarchy"); }

	[MenuItem("KeyRemap/Project #&p")]
	static void KeyRemapProject() { CommonExecuteMenuItem("Window/Project"); }

	[MenuItem("KeyRemap/Animation #&a")]
	static void KeyRemapAnimation() { CommonExecuteMenuItem("Window/Animation"); }

	[MenuItem("KeyRemap/Console #&c")]
	static void KeyRemapConsole() { CommonExecuteMenuItem("Window/Console"); }

	static void CommonExecuteMenuItem(string iStr)
	{
		EditorApplication.ExecuteMenuItem(iStr);
	}
}
