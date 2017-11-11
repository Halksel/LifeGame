using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CellMgr : SingletonMonoBehaviour<CellMgr> {

	private const float CELL_SIZE = 0.5f;
	public int xGridSize = 100;
	public int yGridSize = 100;
	public float turnInterval = 0.5f;
	public Cell[,] cells;
	public GameObject cell;
	public bool[] birth ;
	public bool[] death ;
	public int generationCounter = 0;
	[SerializeField]
	private GameObject editorBase;
	[SerializeField]
	private Text infoText ;
	IEnumerator gameCoroutine;


 	override protected void Awake(){
		base.Awake();
		Init();
		StopAllCoroutines ();
		gameCoroutine = NextTurnCoroutine();
	}
	public void Init(){
		cells = new Cell[xGridSize,yGridSize];
		for(int x = 0; x < xGridSize; ++x){
			for(int y = 0; y < yGridSize;++y){
				GameObject obj = Instantiate(cell) as GameObject;
				obj.transform.parent = transform;
				float xPos = (x - xGridSize * 0.5f) * CELL_SIZE;  
				float yPos = (y - yGridSize * 0.5f) * CELL_SIZE;  
				obj.transform.localPosition = new Vector3 (xPos, yPos,0f); 
				cells[x,y] = obj.GetComponent<Cell>();
				cells[x,y].Init(x,y,Random.Range(0f,100f) < 25f);
			}
		}
	}

	public bool IsValue(int x,int y){
		return 0 <= x && x < xGridSize && 0 <= y && y < yGridSize;
	}

	void Update(){
		if(Input.GetKeyDown(KeyCode.A)){
			NextTurn();
		}
		if(Input.GetKeyDown(KeyCode.S)){
			Start();
		}
		if(Input.GetKeyDown(KeyCode.E)){
			End();
		}
		if(Input.GetKeyDown(KeyCode.C)){
			AllCellDie();
		}
		for (int x = 0; x < xGridSize; ++x) {
			for (int y = 0; y < yGridSize; ++y) {
				cells[x,y].Sync();
			}
		}
	}
	public void Start(){
		StartCoroutine (gameCoroutine);
	}
	public void NextTurn(){
		for (int x = 0; x < xGridSize; ++x) {
			for (int y = 0; y < yGridSize; ++y) {
				cells [x, y].PastTurn ();
			}
		}
		++generationCounter;
		infoText.text = "Generation : " + generationCounter.ToString() + "\n" + "Birth : ";
		for(int i = 0; i < 10;++i){
			if(birth[i]) infoText.text += i.ToString()+ ",";
		}
		infoText.text += "\nDeath : " ;
		for(int i = 0; i < 10;++i){
			if(death[i]) infoText.text += i.ToString() + ",";
		}
	}
	IEnumerator NextTurnCoroutine(){
		while(true){
			NextTurn ();
			yield return new WaitForSeconds (turnInterval);
		}
	}
	public void End(){
		StopCoroutine(gameCoroutine);
	}

	public void AllCellDie(){
		for (int x = 0; x < xGridSize; ++x) {
			for (int y = 0; y < yGridSize; ++y) {
				cells[x,y].Die();
			}
		}
	}
	public void Restart(){
		generationCounter = 0;
		for (int x = 0; x < xGridSize; ++x) {
			for (int y = 0; y < yGridSize; ++y) {
				cells[x,y].Init(x,y,Random.Range(0f,100f) < 25f);
			}
		}
	}
	public void Edit(){
		StopAllCoroutines();
		editorBase.SetActive(!editorBase.activeSelf);
	}

}
